---
name: firebase-fcm
description: Use this skill for Firebase Cloud Messaging, FCM, push notifications, mobile notifications, firebase-admin, notification tokens, device tokens, send notification, topic notifications, scheduled notifications, notificaciones push, Firebase notificaciones, enviar notificación, token de dispositivo.
---

# /firebase-fcm

Workflow para implementar push notifications con Firebase Cloud Messaging (FCM) en NestJS.

## Cuándo usar

- Enviar notificaciones push a dispositivos móviles (iOS/Android)
- Implementar el servicio FCM en un nuevo módulo NestJS
- Depurar notificaciones que no llegan
- Enviar notificaciones a topics (grupos de usuarios)
- Guardar y gestionar device tokens

## Arquitectura

```
Mobile App (React Native / Ionic)
  → Solicita permiso de notificaciones
  → Obtiene token FCM del dispositivo
  → Envía token al backend (PATCH /usuarios/fcm-token)

NestJS Backend
  → Guarda token en la entidad Usuario
  → FcmService.sendToDevice(token, notification)
  → firebase-admin SDK

Firebase Console
  → Credenciales en variables de entorno
  → Reglas de autenticación
```

## Implementación

**Variables de entorno requeridas:**
```env
FIREBASE_PROJECT_ID=tu-proyecto
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@tu-proyecto.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**Módulo Firebase:**
```typescript
// src/common/firebase/firebase.module.ts
import { Module, Global } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';
import { FcmService } from './fcm.service';

@Global()
@Module({
  providers: [
    {
      provide: 'FIREBASE_APP',
      useFactory: (config: ConfigService) => {
        if (admin.apps.length > 0) return admin.apps[0];
        return admin.initializeApp({
          credential: admin.credential.cert({
            projectId:    config.getOrThrow('FIREBASE_PROJECT_ID'),
            clientEmail:  config.getOrThrow('FIREBASE_CLIENT_EMAIL'),
            // Importante: reemplazar \n literales del .env
            privateKey:   config.getOrThrow('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
          }),
        });
      },
      inject: [ConfigService],
    },
    FcmService,
  ],
  exports: [FcmService],
})
export class FirebaseModule {}
```

**FcmService:**
```typescript
// src/common/firebase/fcm.service.ts
import { Injectable, Inject, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

export interface FcmNotification {
  title: string;
  body: string;
  data?: Record<string, string>; // datos extra (siempre string en FCM)
  imageUrl?: string;
}

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);

  constructor(@Inject('FIREBASE_APP') private readonly app: admin.app.App) {}

  // Enviar a un dispositivo específico
  async sendToDevice(token: string, notification: FcmNotification): Promise<boolean> {
    try {
      const result = await this.app.messaging().send({
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data ?? {},
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      this.logger.log(`FCM enviado: ${result}`);
      return true;
    } catch (error) {
      // Token inválido o app desinstalada → limpiar del DB
      if (error.code === 'messaging/registration-token-not-registered') {
        this.logger.warn(`Token FCM inválido — limpiar: ${token.substring(0, 20)}...`);
        return false;
      }
      this.logger.error(`Error FCM: ${error.message}`);
      throw error;
    }
  }

  // Enviar a múltiples dispositivos
  async sendToMultiple(tokens: string[], notification: FcmNotification): Promise<{
    success: number;
    failed: string[]; // tokens inválidos
  }> {
    if (tokens.length === 0) return { success: 0, failed: [] };

    const response = await this.app.messaging().sendEachForMulticast({
      tokens,
      notification: { title: notification.title, body: notification.body },
      data: notification.data ?? {},
    });

    const failedTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
        failedTokens.push(tokens[idx]);
      }
    });

    return { success: response.successCount, failed: failedTokens };
  }

  // Enviar a topic
  async sendToTopic(topic: string, notification: FcmNotification): Promise<void> {
    await this.app.messaging().send({
      topic,
      notification: { title: notification.title, body: notification.body },
      data: notification.data ?? {},
    });
  }
}
```

**Guardar token en el Usuario:**
```typescript
// En el controller de usuarios
@Patch('fcm-token')
@UseGuards(JwtAuthGuard)
async updateFcmToken(
  @CurrentUser() user: JwtPayload,
  @Body() dto: UpdateFcmTokenDto,
) {
  await this.usuariosService.updateFcmToken(user.sub, dto.token);
}

// DTO
export class UpdateFcmTokenDto {
  @IsString() @IsNotEmpty()
  token: string;
}

// Service
async updateFcmToken(userId: number, token: string): Promise<void> {
  await this.repo.update(userId, { fcmToken: token });
}
```

## Debugging

**Notificación no llega:**
```
1. Verificar que el token FCM es válido (no expirado, no desinstalado)
2. Verificar credenciales de Firebase (FIREBASE_PRIVATE_KEY con saltos de línea correctos)
3. Verificar que la app móvil tiene permisos de notificación
4. Probar desde Firebase Console → Cloud Messaging → Send test message
5. Revisar logs del backend — el error de FCM es descriptivo
```

**Token inválido (app desinstalada):**
```typescript
// Cuando sendToDevice retorna false: limpiar el token
const sent = await this.fcmService.sendToDevice(usuario.fcmToken, notif);
if (!sent) {
  await this.usuariosService.updateFcmToken(usuario.id, null);
}
```
