-- ============================================================
-- OPÉRATION IFASTORIA / BRUMATOR
-- Schéma Supabase v3 — Synchronisation temps réel multi-écrans
-- ============================================================

-- 1. Sessions de jeu
CREATE TABLE IF NOT EXISTS game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) DEFAULT 'Opération BRUMATOR',
  active_vignette INTEGER DEFAULT 1,
  active_cell_vignette INTEGER DEFAULT 1,
  timer_seconds INTEGER DEFAULT 5400,
  timer_running BOOLEAN DEFAULT FALSE,
  timer_started_at TIMESTAMPTZ,
  synth_phase INTEGER DEFAULT 3,
  status VARCHAR(20) DEFAULT 'lobby',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Joueurs connectés
CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  cell_id VARCHAR(20) NOT NULL,
  role VARCHAR(20) DEFAULT 'player',
  display_name VARCHAR(50),
  connected BOOLEAN DEFAULT TRUE,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Injections envoyées par l'animateur
CREATE TABLE IF NOT EXISTS injections_sent (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  vignette INTEGER NOT NULL,
  injection_id INTEGER NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, vignette, injection_id)
);

-- 4. Types révélés (classification dévoilée aux cellules)
CREATE TABLE IF NOT EXISTS revealed_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  vignette INTEGER NOT NULL,
  injection_id INTEGER NOT NULL,
  revealed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, vignette, injection_id)
);

-- 5. Boîte de réception des cellules
CREATE TABLE IF NOT EXISTS cell_inbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  cell_id VARCHAR(20) NOT NULL,
  vignette INTEGER NOT NULL,
  injection_id INTEGER NOT NULL,
  message_type VARCHAR(20),
  contenu TEXT,
  canal VARCHAR(100),
  source VARCHAR(200),
  fiabilite VARCHAR(10),
  heure VARCHAR(20),
  is_media BOOLEAN DEFAULT FALSE,
  is_call BOOLEAN DEFAULT FALSE,
  is_custom BOOLEAN DEFAULT FALSE,
  received_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Messages chat inter-cellules
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  from_cell VARCHAR(20) NOT NULL,
  channel VARCHAR(50) NOT NULL,
  text TEXT NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Items de presse poussés
CREATE TABLE IF NOT EXISTS press_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  media_id VARCHAR(50) NOT NULL,
  vignette INTEGER NOT NULL,
  pushed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, media_id)
);

-- 8. Marqueurs carte tactique
CREATE TABLE IF NOT EXISTS map_markers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  marker_type VARCHAR(20) NOT NULL,
  x REAL NOT NULL,
  y REAL NOT NULL,
  label VARCHAR(200),
  dest TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Synthèses des cellules — TOUTES LES PHASES (1 à 5)
CREATE TABLE IF NOT EXISTS cell_syntheses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  cell_id VARCHAR(20) NOT NULL,
  -- Phase 1 : Classification
  confirmed TEXT DEFAULT '',
  to_verify TEXT DEFAULT '',
  intox TEXT DEFAULT '',
  -- Phase 2 : Priorités
  priority1 TEXT DEFAULT '',
  priority2 TEXT DEFAULT '',
  priority3 TEXT DEFAULT '',
  -- Phase 3 : Intention
  en_vue_de TEXT DEFAULT '',
  je_veux TEXT DEFAULT '',
  a_cet_effet TEXT DEFAULT '',
  -- Phase 4 : Décision
  decision TEXT DEFAULT '',
  analyse_synth TEXT DEFAULT '',
  preco_coord TEXT DEFAULT '',
  actions_anticiper TEXT DEFAULT '',
  -- Phase 5 : Retex
  retex TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, cell_id)
);

-- 10. SITREP animateur et cellules
CREATE TABLE IF NOT EXISTS sitreps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  cell_id VARCHAR(20) NOT NULL DEFAULT 'global',
  operation VARCHAR(50) DEFAULT 'BRUMATOR',
  zone VARCHAR(100) DEFAULT '',
  date_heure VARCHAR(50) DEFAULT '',
  emetteur VARCHAR(100) DEFAULT '',
  classification VARCHAR(50) DEFAULT '',
  sit_generale TEXT DEFAULT '',
  sit_ennemie TEXT DEFAULT '',
  sit_forces_ifa TEXT DEFAULT '',
  evenements TEXT DEFAULT '',
  infra_port TEXT DEFAULT '',
  infra_aeroport TEXT DEFAULT '',
  infra_governator TEXT DEFAULT '',
  logistique TEXT DEFAULT '',
  evaluation TEXT DEFAULT '',
  actions_cours TEXT DEFAULT '',
  decisions TEXT DEFAULT '',
  synthese_cmd TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, cell_id)
);

-- 11. Alertes plein écran
CREATE TABLE IF NOT EXISTS fullscreen_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  icon VARCHAR(10) DEFAULT '🚨',
  color VARCHAR(10) DEFAULT '#e63946',
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Journal animateur
CREATE TABLE IF NOT EXISTS facilitator_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
  vignette INTEGER,
  cell_id VARCHAR(20),
  observation TEXT NOT NULL,
  category VARCHAR(30),
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEX pour performances temps réel
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cell_inbox_session ON cell_inbox(session_id, cell_id);
CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_messages(session_id, channel);
CREATE INDEX IF NOT EXISTS idx_injections_session ON injections_sent(session_id, vignette);
CREATE INDEX IF NOT EXISTS idx_players_session ON players(session_id);
CREATE INDEX IF NOT EXISTS idx_press_session ON press_items(session_id);
CREATE INDEX IF NOT EXISTS idx_syntheses_session ON cell_syntheses(session_id, cell_id);
CREATE INDEX IF NOT EXISTS idx_sitreps_session ON sitreps(session_id, cell_id);
CREATE INDEX IF NOT EXISTS idx_alerts_session ON fullscreen_alerts(session_id);
CREATE INDEX IF NOT EXISTS idx_markers_session ON map_markers(session_id);

-- ============================================================
-- REALTIME : Activer les publications pour TOUTES les tables
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE game_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE players;
ALTER PUBLICATION supabase_realtime ADD TABLE injections_sent;
ALTER PUBLICATION supabase_realtime ADD TABLE revealed_types;
ALTER PUBLICATION supabase_realtime ADD TABLE cell_inbox;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE press_items;
ALTER PUBLICATION supabase_realtime ADD TABLE map_markers;
ALTER PUBLICATION supabase_realtime ADD TABLE cell_syntheses;
ALTER PUBLICATION supabase_realtime ADD TABLE sitreps;
ALTER PUBLICATION supabase_realtime ADD TABLE fullscreen_alerts;

-- ============================================================
-- RLS (Row Level Security) — Accès ouvert pour prototype
-- ============================================================
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE injections_sent ENABLE ROW LEVEL SECURITY;
ALTER TABLE revealed_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE cell_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE press_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE cell_syntheses ENABLE ROW LEVEL SECURITY;
ALTER TABLE sitreps ENABLE ROW LEVEL SECURITY;
ALTER TABLE fullscreen_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE facilitator_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_sessions" ON game_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_players" ON players FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_injections" ON injections_sent FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_revealed" ON revealed_types FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_inbox" ON cell_inbox FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_chat" ON chat_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_press" ON press_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_markers" ON map_markers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_syntheses" ON cell_syntheses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_sitreps" ON sitreps FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_alerts" ON fullscreen_alerts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_log" ON facilitator_log FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- TRIGGERS : mise à jour automatique de updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_session_updated
  BEFORE UPDATE ON game_sessions
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_synthese_updated
  BEFORE UPDATE ON cell_syntheses
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_sitrep_updated
  BEFORE UPDATE ON sitreps
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ============================================================
-- FONCTION utilitaire : générer un code session
-- ============================================================
CREATE OR REPLACE FUNCTION generate_session_code()
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    new_code := 'BRU-' || LPAD(FLOOR(RANDOM() * 100)::TEXT, 2, '0');
    SELECT EXISTS(SELECT 1 FROM game_sessions WHERE code = new_code) INTO code_exists;
    EXIT WHEN NOT code_exists;
  END LOOP;
  RETURN new_code;
END;
$$ LANGUAGE plpgsql;
