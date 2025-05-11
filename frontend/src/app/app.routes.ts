import { Routes } from '@angular/router';
import { VaultExploreComponent } from './components/vault-explore/vault-explore.component';
import { HomeComponent } from './components/home/home.component';

export const routes: Routes = [
    {
        path: '', redirectTo: '/home', pathMatch: 'full'
    },
    {
        path: 'home',
        component: HomeComponent
    },
    {
        path: 'explore',
        component: VaultExploreComponent
    }
];
