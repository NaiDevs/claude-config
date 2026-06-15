---
description: Asistente para Testing — genera unit tests, e2e y mocks para Angular (Karma/Vitest), NestJS (Jest), .NET (xUnit) y React Native según el proyecto activo
---

# testing

Asistente para testing en los proyectos. Detecta el framework de test del proyecto activo y genera specs, mocks y configuración correcta.

## Uso

```
/testing unit <nombre>               → unit test para un componente, servicio o clase
/testing e2e <flujo>                 → test e2e (Cypress para Angular, Playwright para .NET)
/testing mock <dependencia>          → genera mock/spy de una dependencia
/testing api <endpoint>              → test de integración para un endpoint REST
/testing coverage                    → muestra cobertura y sugiere tests faltantes
/testing setup                       → configura el framework de test en el proyecto
/testing fix                         → detecta tests rotos y sugiere fixes
```

## Framework por proyecto

| Alias | Framework | Runner |
|---|---|---|
| bodega bo api, bodega services, yalo admin api | Jest 29 + ts-jest | `npm test` |
| nai restaurant api | Jest 30 + ts-jest | `npm test` |
| yalo bo (POS) | Karma + Jasmine + **Cypress** (e2e) | `ng test` / `ng e2e` |
| yalo agendo, yalo console, yalo consumer | **Vitest** 4.x | `npm test` |
| nai inhands bo (Angular 21) | **Vitest** 4.x | `npm test` |
| ult bo / ult ecom (NX) | **Jest** 29 + jest-preset-angular | `nx test` |
| corinsa bi fe, cpa fe, doctor fe | Karma + Jasmine | `ng test` |
| yalo bo api, yalo reporteria (.NET) | **xUnit** / NUnit | `dotnet test` |
| yalo admin api (NestJS) | Jest + **Playwright** (e2e) | `npm test` |

---

## NestJS — Jest

### `/testing unit <nombre>` — Servicio NestJS

```typescript
// src/<nombre>s/<nombre>.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { <Nombre>Service } from './<nombre>.service';
import { <Nombre> } from './entities/<nombre>.entity';

describe('<Nombre>Service', () => {
  let service: <Nombre>Service;
  let repo: jest.Mocked<Repository<<Nombre>>>;

  const mockRepo = {
    findAndCount: jest.fn(),
    findOne:      jest.fn(),
    findOneBy:    jest.fn(),
    create:       jest.fn(),
    save:         jest.fn(),
    update:       jest.fn(),
    delete:       jest.fn(),
    softDelete:   jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        <Nombre>Service,
        { provide: getRepositoryToken(<Nombre>), useValue: mockRepo },
      ],
    }).compile();

    service = module.get<<Nombre>Service>(<Nombre>Service);
    repo    = module.get(getRepositoryToken(<Nombre>));
  });

  afterEach(() => jest.clearAllMocks());

  describe('findAll', () => {
    it('debería retornar lista paginada', async () => {
      const mockData = [{ id: 1, nombre: 'Test' }] as <Nombre>[];
      mockRepo.findAndCount.mockResolvedValue([mockData, 1]);

      const result = await service.findAll({ page: 1, limit: 10 });

      expect(result.data).toEqual(mockData);
      expect(result.total).toBe(1);
      expect(repo.findAndCount).toHaveBeenCalledTimes(1);
    });
  });

  describe('findOne', () => {
    it('debería retornar el item si existe', async () => {
      const mock = { id: 1, nombre: 'Test' } as <Nombre>;
      mockRepo.findOneBy.mockResolvedValue(mock);

      const result = await service.findOne(1);
      expect(result).toEqual(mock);
    });

    it('debería lanzar NotFoundException si no existe', async () => {
      mockRepo.findOneBy.mockResolvedValue(null);
      await expect(service.findOne(999)).rejects.toThrow('no encontrado');
    });
  });

  describe('create', () => {
    it('debería crear y retornar el nuevo item', async () => {
      const dto   = { nombre: 'Nuevo' };
      const saved = { id: 1, ...dto } as <Nombre>;
      mockRepo.create.mockReturnValue(saved);
      mockRepo.save.mockResolvedValue(saved);

      const result = await service.create(dto);
      expect(result).toEqual(saved);
      expect(repo.save).toHaveBeenCalledWith(saved);
    });
  });
});
```

### `/testing api <endpoint>` — Test de integración NestJS (Supertest)

```typescript
// test/<nombre>.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('<Nombre>Controller (e2e)', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = module.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();

    // Login y obtener token
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'test@test.com', password: 'Test123!' });
    authToken = loginRes.body.accessToken;
  });

  afterAll(() => app.close());

  describe('GET /<nombre>s', () => {
    it('200 con lista paginada', () => {
      return request(app.getHttpServer())
        .get('/<nombre>s?page=1&limit=10')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect(({ body }) => {
          expect(body.data).toBeInstanceOf(Array);
          expect(body.total).toBeGreaterThanOrEqual(0);
        });
    });

    it('401 sin token', () => {
      return request(app.getHttpServer())
        .get('/<nombre>s')
        .expect(401);
    });
  });

  describe('POST /<nombre>s', () => {
    it('201 crea correctamente', () => {
      return request(app.getHttpServer())
        .post('/<nombre>s')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ nombre: 'Test Item' })
        .expect(201)
        .expect(({ body }) => {
          expect(body.id).toBeDefined();
          expect(body.nombre).toBe('Test Item');
        });
    });

    it('400 con datos inválidos', () => {
      return request(app.getHttpServer())
        .post('/<nombre>s')
        .set('Authorization', `Bearer ${authToken}`)
        .send({})  // sin nombre requerido
        .expect(400);
    });
  });
});
```

---

## Angular — Vitest (proyectos modernos Angular 19+)

### `/testing unit <nombre>` — Componente Angular con Vitest

```typescript
// src/app/<nombre>/<nombre>.component.spec.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { <Nombre>Component } from './<nombre>.component';
import { <Nombre>Service } from './<nombre>.service';
import { of } from 'rxjs';

describe('<Nombre>Component', () => {
  let component: <Nombre>Component;
  let service: jest.Mocked<<Nombre>Service>;

  const mockService = {
    getAll:  vi.fn().mockReturnValue(of([])),
    create:  vi.fn(),
    delete:  vi.fn(),
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [<Nombre>Component],
      providers: [
        { provide: <Nombre>Service, useValue: mockService },
      ],
    }).compileComponents();

    component = TestBed.createComponent(<Nombre>Component).componentInstance;
  });

  it('debería crearse', () => {
    expect(component).toBeTruthy();
  });

  it('debería cargar items al inicializar', () => {
    const items = [{ id: 1, nombre: 'Test' }];
    mockService.getAll.mockReturnValue(of(items));

    component.ngOnInit();

    expect(component.items()).toEqual(items);  // si usa signal
  });
});
```

## Angular — Karma + Jasmine (proyectos legacy Angular < 18)

```typescript
// src/app/<nombre>/<nombre>.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { <Nombre>Component } from './<nombre>.component';
import { <Nombre>Service } from './<nombre>.service';
import { of } from 'rxjs';

describe('<Nombre>Component', () => {
  let component: <Nombre>Component;
  let fixture: ComponentFixture<<Nombre>Component>;
  let serviceSpy: jasmine.SpyObj<<Nombre>Service>;

  beforeEach(async () => {
    serviceSpy = jasmine.createSpyObj('<Nombre>Service', ['getAll', 'create', 'delete']);
    serviceSpy.getAll.and.returnValue(of([]));

    await TestBed.configureTestingModule({
      declarations: [<Nombre>Component],
      imports: [HttpClientTestingModule],
      providers: [{ provide: <Nombre>Service, useValue: serviceSpy }],
    }).compileComponents();

    fixture   = TestBed.createComponent(<Nombre>Component);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('debería crearse', () => expect(component).toBeTruthy());

  it('debería llamar getAll en ngOnInit', () => {
    expect(serviceSpy.getAll).toHaveBeenCalled();
  });
});
```

### `/testing unit <nombre>` — Servicio Angular con HttpClient

```typescript
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { <Nombre>Service } from './<nombre>.service';

describe('<Nombre>Service', () => {
  let service: <Nombre>Service;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [<Nombre>Service],
    });
    service = TestBed.inject(<Nombre>Service);
    http    = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());  // verifica que no queden requests pendientes

  it('getAll debería hacer GET /api/<nombre>s', () => {
    const mockData = [{ id: 1, nombre: 'Test' }];
    service.getAll().subscribe(data => expect(data).toEqual(mockData));

    const req = http.expectOne('/api/<nombre>s');
    expect(req.request.method).toBe('GET');
    req.flush(mockData);
  });
});
```

---

## .NET — xUnit

### `/testing unit <nombre>` — Servicio .NET con xUnit + Moq

```csharp
// Tests/<Nombre>ServiceTests.cs
public class <Nombre>ServiceTests
{
    private readonly Mock<I<Nombre>Repository> _mockRepo;
    private readonly Mock<ILogger<<Nombre>Service>> _mockLogger;
    private readonly <Nombre>Service _service;

    public <Nombre>ServiceTests()
    {
        _mockRepo   = new Mock<I<Nombre>Repository>();
        _mockLogger = new Mock<ILogger<<Nombre>Service>>();
        _service    = new <Nombre>Service(_mockRepo.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetAllAsync_DeberiaRetornarLista()
    {
        // Arrange
        var expected = new List<<Nombre>>
        {
            new() { Id = 1, Nombre = "Test 1" },
            new() { Id = 2, Nombre = "Test 2" },
        };
        _mockRepo.Setup(r => r.GetAllAsync(It.IsAny<CancellationToken>()))
                 .ReturnsAsync(expected);

        // Act
        var result = await _service.GetAllAsync();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(2, result.Count());
    }

    [Fact]
    public async Task GetByIdAsync_CuandoNoExiste_LanzaNotFoundException()
    {
        _mockRepo.Setup(r => r.GetByIdAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
                 .ReturnsAsync(((<Nombre>?)null));

        await Assert.ThrowsAsync<NotFoundException>(
            () => _service.GetByIdAsync(999));
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    [InlineData("  ")]
    public async Task CreateAsync_ConNombreInvalido_LanzaValidationException(string nombre)
    {
        var dto = new Create<Nombre>Request(nombre, null);
        await Assert.ThrowsAsync<ValidationException>(
            () => _service.CreateAsync(dto));
    }
}
```

### `/testing api <endpoint>` — Test de integración .NET (WebApplicationFactory)

```csharp
public class <Nombre>ControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public <Nombre>ControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
            builder.ConfigureServices(services =>
            {
                // Reemplazar DB por InMemory para tests
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);

                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            }))
            .CreateClient();
    }

    [Fact]
    public async Task GET_<Nombre>s_Retorna200()
    {
        var response = await _client.GetAsync("/api/v1/<nombre>s");
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<PaginatedResult<<Nombre>Response>>();
        Assert.NotNull(body);
    }

    [Fact]
    public async Task POST_<Nombre>_ConDatosValidos_Retorna201()
    {
        var dto = new Create<Nombre>Request("Test", null);
        var response = await _client.PostAsJsonAsync("/api/v1/<nombre>s", dto);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
```

---

## `/testing mock <dependencia>`

Mocks más comunes por proyecto:

```typescript
// NestJS — mock de ConfigService
const mockConfig = { get: jest.fn(), getOrThrow: jest.fn() };

// NestJS — mock de JwtService
const mockJwt = { sign: jest.fn().mockReturnValue('mock-token'), verify: jest.fn() };

// NestJS — mock de servicio externo (SendGrid, AWS, etc.)
const mockEmailService = { sendEmail: jest.fn().mockResolvedValue(undefined) };

// Angular — mock de Router
const mockRouter = { navigate: jasmine.createSpy('navigate') };

// Angular — mock de MatDialog
const mockDialog = { open: jasmine.createSpy('open').and.returnValue({
  afterClosed: () => of(null)
})};
```

---

## `/testing coverage`

```bash
# NestJS
npm run test:cov
# genera reporte en coverage/lcov-report/index.html

# Angular (Karma)
ng test --code-coverage
# genera coverage/

# Angular (Vitest)
npm run test:coverage

# .NET
dotnet test --collect:"XPlat Code Coverage"
# genera coverage.xml — ver con ReportGenerator
```

Umbrales recomendados: **70%** líneas para servicios/controllers. **No** forzar 100% en componentes UI.
