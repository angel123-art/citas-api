-- ----- Seguridad y configuración -----
CREATE TABLE roles (
  id      BIGINT       NOT NULL AUTO_INCREMENT,
  nombre  VARCHAR(20)  NOT NULL,           -- GERENTE, TERAPISTA, ADMIN, CLIENTE, RECEPCIONISTA
  PRIMARY KEY (id),
  UNIQUE KEY uk_roles_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id             BIGINT        NOT NULL AUTO_INCREMENT,
  email          VARCHAR(100)  NOT NULL,
  password       VARCHAR(60)   NOT NULL,   -- texto plano SOLO para aprender (la próxima clase se cifra)
  rol_id         BIGINT        NOT NULL,
  activo         BOOLEAN       NOT NULL DEFAULT TRUE,
  creado_en      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_usuarios_email (email),
  CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES roles (id)
) ENGINE=InnoDB;

CREATE TABLE parametros (
  id           BIGINT        NOT NULL AUTO_INCREMENT,
  clave        VARCHAR(40)   NOT NULL,
  valor        VARCHAR(100)  NOT NULL,
  descripcion  VARCHAR(255)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_parametros_clave (clave)
) ENGINE=InnoDB;

CREATE TABLE auditoria (
  id           BIGINT       NOT NULL AUTO_INCREMENT,
  usuario_id   BIGINT       NOT NULL,
  accion       VARCHAR(20)  NOT NULL,      -- LOGIN, CREAR, ACTUALIZAR, ELIMINAR
  tabla        VARCHAR(40)  NULL,
  registro_id  BIGINT       NULL,
  fecha        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_auditoria_usuario_fecha (usuario_id, fecha),
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

-- ----- Catálogo y personal -----
CREATE TABLE servicios (
  id           BIGINT        NOT NULL AUTO_INCREMENT,
  titulo       VARCHAR(80)   NOT NULL,
  descripcion  VARCHAR(255)  NULL,
  costo        DECIMAL(8,2)  NOT NULL,     -- incluye IGV
  duracion     INT           NOT NULL,     -- minutos
  foto         VARCHAR(255)  NULL,         -- URL o ruta de la imagen
  activo       BOOLEAN       NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_servicios_titulo (titulo),
  CONSTRAINT ck_servicios_costo CHECK (costo >= 0),
  CONSTRAINT ck_servicios_duracion CHECK (duracion BETWEEN 15 AND 180)
) ENGINE=InnoDB;

CREATE TABLE recepcionistas (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  usuario_id  BIGINT       NOT NULL,
  nombres     VARCHAR(60)  NOT NULL,
  apellidos   VARCHAR(60)  NOT NULL,
  dni         VARCHAR(8)   NOT NULL,
  telefono    VARCHAR(15)  NULL,
  turno       VARCHAR(10)  NOT NULL,       -- MANANA, TARDE
  PRIMARY KEY (id),
  UNIQUE KEY uk_recepcionistas_usuario (usuario_id),
  UNIQUE KEY uk_recepcionistas_dni (dni),
  CONSTRAINT fk_recepcionistas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

CREATE TABLE terapistas (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  usuario_id  BIGINT       NOT NULL,
  nombres     VARCHAR(60)  NOT NULL,
  apellidos   VARCHAR(60)  NOT NULL,
  dni         VARCHAR(8)   NOT NULL,
  telefono    VARCHAR(15)  NULL,
  activo      BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_terapistas_usuario (usuario_id),
  UNIQUE KEY uk_terapistas_dni (dni),
  CONSTRAINT fk_terapistas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

CREATE TABLE horarios (
  id            BIGINT   NOT NULL AUTO_INCREMENT,
  terapista_id  BIGINT   NOT NULL,
  dia_semana    TINYINT  NOT NULL,         -- 1 = lunes ... 7 = domingo
  hora_inicio   TIME     NOT NULL,
  hora_fin      TIME     NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_horarios (terapista_id, dia_semana, hora_inicio),
  CONSTRAINT fk_horarios_terapista FOREIGN KEY (terapista_id) REFERENCES terapistas (id),
  CONSTRAINT ck_horarios_dia CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT ck_horarios_horas CHECK (hora_inicio < hora_fin)
) ENGINE=InnoDB;

CREATE TABLE terapista_servicios (
  id            BIGINT  NOT NULL AUTO_INCREMENT,
  terapista_id  BIGINT  NOT NULL,
  servicio_id   BIGINT  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_terapista_servicio (terapista_id, servicio_id),
  CONSTRAINT fk_ts_terapista FOREIGN KEY (terapista_id) REFERENCES terapistas (id),
  CONSTRAINT fk_ts_servicio  FOREIGN KEY (servicio_id)  REFERENCES servicios (id)
) ENGINE=InnoDB;

-- ----- Clientes -----
CREATE TABLE clientes (
  id                BIGINT        NOT NULL AUTO_INCREMENT,
  usuario_id        BIGINT        NULL,    -- NULL: cliente sin cuenta en el sistema
  nombres           VARCHAR(60)   NOT NULL,
  apellidos         VARCHAR(60)   NOT NULL,
  dni               VARCHAR(8)    NOT NULL,
  fecha_nacimiento  DATE          NOT NULL,
  telefono          VARCHAR(15)   NULL,
  correo            VARCHAR(100)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_clientes_usuario (usuario_id),
  UNIQUE KEY uk_clientes_dni (dni),
  CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

-- ----- Historia del cliente -----
CREATE TABLE antecedentes (
  id           BIGINT        NOT NULL AUTO_INCREMENT,
  cliente_id   BIGINT        NOT NULL,
  fecha        DATE          NOT NULL,     -- hasta hoy (si no se envía, el servidor pone la de hoy)
  descripcion  VARCHAR(2000) NOT NULL,     -- texto libre: alergias, enfermedades, cirugías, medicación...
  PRIMARY KEY (id),
  KEY ix_antecedentes_cliente_fecha (cliente_id, fecha),
  CONSTRAINT fk_antecedentes_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (id)
) ENGINE=InnoDB;

CREATE TABLE consultas (
  id            BIGINT        NOT NULL AUTO_INCREMENT,
  cliente_id    BIGINT        NOT NULL,
  usuario_id    BIGINT        NOT NULL,    -- gerente que atendió la consulta
  fecha         DATE          NOT NULL,
  indicaciones  VARCHAR(500)  NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_consultas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (id),
  CONSTRAINT fk_consultas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

CREATE TABLE consulta_servicios (
  id           BIGINT  NOT NULL AUTO_INCREMENT,
  consulta_id  BIGINT  NOT NULL,
  servicio_id  BIGINT  NOT NULL,
  sesiones     INT     NOT NULL,           -- sesiones sugeridas de ese servicio
  PRIMARY KEY (id),
  UNIQUE KEY uk_consulta_servicio (consulta_id, servicio_id),
  CONSTRAINT fk_cs_consulta FOREIGN KEY (consulta_id) REFERENCES consultas (id),
  CONSTRAINT fk_cs_servicio FOREIGN KEY (servicio_id) REFERENCES servicios (id),
  CONSTRAINT ck_cs_sesiones CHECK (sesiones > 0)
) ENGINE=InnoDB;

-- ----- Citas (la Recepcionista registra inicio y fin, el Cliente valora) -----
CREATE TABLE citas (
  id                BIGINT       NOT NULL AUTO_INCREMENT,
  cliente_id        BIGINT       NOT NULL,
  terapista_id      BIGINT       NOT NULL,
  servicio_id       BIGINT       NOT NULL,
  recepcionista_id  BIGINT       NULL,     -- quién registró la atención
  hora_programada   DATETIME     NOT NULL,
  hora_inicio       DATETIME     NULL,     -- hora real de inicio
  hora_fin          DATETIME     NULL,     -- hora real de fin
  estado            VARCHAR(12)  NOT NULL DEFAULT 'RESERVADA',  -- RESERVADA, EN_ATENCION, ATENDIDA, CANCELADA
  valoracion        TINYINT      NULL,     -- 1 a 5, la da el cliente al terminar
  PRIMARY KEY (id),
  UNIQUE KEY uk_citas_terapista_hora (terapista_id, hora_programada),
  KEY ix_citas_cliente (cliente_id, hora_programada),
  CONSTRAINT fk_citas_cliente       FOREIGN KEY (cliente_id)       REFERENCES clientes (id),
  CONSTRAINT fk_citas_terapista     FOREIGN KEY (terapista_id)     REFERENCES terapistas (id),
  CONSTRAINT fk_citas_servicio      FOREIGN KEY (servicio_id)      REFERENCES servicios (id),
  CONSTRAINT fk_citas_recepcionista FOREIGN KEY (recepcionista_id) REFERENCES recepcionistas (id),
  CONSTRAINT ck_citas_valoracion CHECK (valoracion IS NULL OR valoracion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ----- Cobros -----
CREATE TABLE comprobantes (
  id          BIGINT        NOT NULL AUTO_INCREMENT,
  cita_id     BIGINT        NOT NULL,
  cliente_id  BIGINT        NOT NULL,
  tipo        VARCHAR(7)    NOT NULL,      -- BOLETA, FACTURA
  serie       VARCHAR(4)    NOT NULL,      -- B001, F001
  numero      INT           NOT NULL,
  fecha       DATETIME      NOT NULL,
  subtotal    DECIMAL(8,2)  NOT NULL,
  igv         DECIMAL(8,2)  NOT NULL,
  total       DECIMAL(8,2)  NOT NULL,
  estado      VARCHAR(10)   NOT NULL DEFAULT 'EMITIDO',  -- EMITIDO, ANULADO
  PRIMARY KEY (id),
  KEY ix_comprobantes_cita (cita_id),     -- una cita puede tener un comprobante ANULADO y otro EMITIDO
  UNIQUE KEY uk_comprobantes_serie_numero (serie, numero),
  CONSTRAINT fk_comprobantes_cita    FOREIGN KEY (cita_id)    REFERENCES citas (id),
  CONSTRAINT fk_comprobantes_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (id)
) ENGINE=InnoDB;

CREATE TABLE pagos (
  id              BIGINT        NOT NULL AUTO_INCREMENT,
  comprobante_id  BIGINT        NOT NULL,
  metodo          VARCHAR(10)   NOT NULL,  -- EFECTIVO, TARJETA, YAPE, PLIN
  monto           DECIMAL(8,2)  NOT NULL,
  fecha           DATETIME      NOT NULL,
  nro_operacion   VARCHAR(30)   NULL,      -- obligatorio en TARJETA, YAPE y PLIN
  PRIMARY KEY (id),
  CONSTRAINT fk_pagos_comprobante FOREIGN KEY (comprobante_id) REFERENCES comprobantes (id),
  CONSTRAINT ck_pagos_monto CHECK (monto > 0)
) ENGINE=InnoDB;

