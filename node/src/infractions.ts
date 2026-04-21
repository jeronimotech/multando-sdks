/**
 * Infractions service for the Multando API.
 */

import { HttpClient } from './http.js';
import type { Infraction } from './models.js';

export class InfractionsService {
  constructor(private readonly http: HttpClient) {}

  async list(): Promise<Infraction[]> {
    return this.http.get<Infraction[]>('/infractions');
  }

  async get(id: number): Promise<Infraction> {
    return this.http.get<Infraction>(`/infractions/${id}`);
  }
}
