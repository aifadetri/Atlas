/* Общие рейтинги и статистика. В этом файле используются только публичные данные. */
(() => {
  'use strict';
  const config = window.ATLAS_SUPABASE;
  const db = window.supabase.createClient(config.url, config.publishableKey, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, storageKey: 'atlas-cloud-auth' }
  });
  const cloud = window.AtlasCloud = {
    db, status: 'loading', error: '', user: null, profiles: [], board: [], boardKey: null,
    statistics: [], statsPlayer: null, statsLoading: false, statsError: '',
    emit() { window.dispatchEvent(new CustomEvent('atlas-cloud-change')); },
    message(error) {
      if (error?.code === 'PGRST205' || error?.code === 'PGRST202') return 'База ещё не настроена. Выполни SQL из инструкции Supabase.';
      if (/anonymous.*disabled/i.test(error?.message || '')) return 'Гостевой вход пока выключен в настройках Supabase.';
      return error?.message || 'Не удалось связаться с Supabase. Проверь интернет и повтори.';
    },
    async initialize() {
      try {
        const { data, error } = await db.auth.getSession();
        if (error) throw error;
        this.user = data.session?.user || null;
        await this.refreshProfiles();
        this.status = 'ready'; this.error = '';
      } catch (error) { this.status = 'error'; this.error = this.message(error); }
      this.emit();
    },
    async refreshProfiles() {
      const { data, error } = await db.from('atlas_profiles').select('id,nickname').order('nickname').limit(1000);
      if (error) throw error;
      this.profiles = data; return data;
    },
    async ensurePlayer(nickname) {
      if (!this.user) {
        const { data, error } = await db.auth.signInAnonymously();
        if (error) throw new Error(this.message(error));
        this.user = data.user;
      }
      const { error } = await db.rpc('atlas_set_profile', { p_nickname: nickname });
      if (error) throw new Error(this.message(error));
      await this.refreshProfiles();
      this.status = 'ready'; this.emit();
      return this.user.id;
    },
    async refreshBoard(key) {
      this.boardKey = key; this.board = []; this.boardLoading = true; this.boardError = '';
      try {
        const { data, error } = await db.rpc('atlas_leaderboard', { p_key: key });
        if (error) throw error;
        if (this.boardKey === key) this.board = data.map(r => ({ ...r, playerId: r.player_id, date: new Date(r.created_at).getTime(), seconds: Number(r.seconds) }));
      } catch (error) { if (this.boardKey === key) this.boardError = this.message(error); }
      if (this.boardKey === key) { this.boardLoading = false; this.emit(); }
    },
    async loadStats(playerId) {
      this.statsPlayer = playerId; this.statistics = []; this.statsLoading = true; this.statsError = '';
      try {
        const { data, error } = await db.from('atlas_games').select('id,player_id,key,score,accuracy,seconds,total,correct,answers,created_at')
          .eq('player_id', playerId).order('created_at', { ascending: false }).limit(1000);
        if (error) throw error;
        const nickname = this.profiles.find(p => p.id === playerId)?.nickname || 'Игрок';
        if (this.statsPlayer === playerId) this.statistics = data.map(r => ({ ...r, playerId: r.player_id, nickname, seconds: Number(r.seconds), date: new Date(r.created_at).getTime() }));
      } catch (error) { if (this.statsPlayer === playerId) this.statsError = this.message(error); }
      if (this.statsPlayer === playerId) { this.statsLoading = false; this.emit(); }
    },
    async save(record) {
      if (!this.user || record.playerId !== this.user.id) throw new Error('Для отправки этой партии войди в тот профиль, в котором играл.');
      const { error } = await db.rpc('atlas_submit_game', {
        p_id: record.id, p_key: record.key, p_seconds: record.seconds, p_answers: record.answers
      });
      if (error) throw new Error(this.message(error));
      await this.refreshBoard(record.key);
      if (this.statsPlayer === record.playerId) await this.loadStats(record.playerId);
    },
    async emailLink(email) {
      const { error } = await db.auth.signInWithOtp({ email, options: { emailRedirectTo: config.redirectUrl } });
      if (error) throw new Error(this.message(error));
    },
    async signOut() {
      const { error } = await db.auth.signOut(); if (error) throw error;
      this.user = null; this.emit();
    }
  };
  db.auth.onAuthStateChange((_event, session) => {
    cloud.user = session?.user || null;
    // Не выполнять запросы Supabase внутри синхронного auth callback.
    setTimeout(() => cloud.emit(), 0);
  });
})();
