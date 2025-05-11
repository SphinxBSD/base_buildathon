import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, from } from 'rxjs';
import { ethers } from 'ethers';

import { MetaMaskInpageProvider } from '@metamask/providers';
declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider;
  }
}

@Injectable({
  providedIn: 'root'
})
export class Web3Service {
  private provider: ethers.BrowserProvider | null = null;
  private signer: ethers.JsonRpcSigner | null = null;
  // Falta aqui declarar la VaultFactory                                                        <----------------------------------------

  public isConnected$ = new BehaviorSubject<boolean>(false);
  public account$ = new BehaviorSubject<string>('');
  public networkId$ = new BehaviorSubject<number>(0);
  // Falta declara el contrato Observable Vault                                                  <----------------------------------------

  constructor() {
    this.initWeb3();
  }

  async initWeb3(): Promise<void> {
    // Check if Metamask instaled
    if (window.ethereum) {
      try {
        this.provider = new ethers.BrowserProvider(window.ethereum);

        // Solicitar el acceso a la cuenta
        const accounts = await window.ethereum.request({method: 'eth_requesAccounts'});
        if (accounts && Array.isArray(accounts) && accounts.length >0){
          this.account$.next(accounts[0] as string);
        }

        // Get Signer
        this.signer = await this.provider.getSigner();

        // Obtener Id de la network
        const network = await this.provider.getNetwork();
        this.networkId$.next(Number(network.chainId));

        // Initialize contracts
        // await this.initContracts();                                            <----------------------------------------

        // Set uyp event listeners
        window.ethereum.on('accountsChanged', (accounts: unknown) => {
          if (Array.isArray(accounts) && accounts.length > 0) {
            this.account$.next(accounts[0] as string);
            // this.users                                                         <----------------------------------------
          }
        });

        window.ethereum.on('chainChanged', () => {
          window.location.reload();
        });
        
        this.isConnected$.next(true);
        // await this.loadUsers                                                   <-------------------------------------
      } catch (error) {
        console.error('Error Initializing Web3', error);
      }
    } else {
      console.error('Please Install Metamask');
    }
  }

  private async initContracts(): Promise<void> {
    //                                                                            <-------------------------------------
  }

  async connectWallet(): Promise<void> {
    if (!this.provider) {
      await this.initWeb3();
      return;
    }

    try {
      const accounts = await window.ethereum?.request({ method: 'eth_requestAccounts'});
      if (accounts && Array.isArray(accounts) && accounts.length > 0) {
        this.account$.next(accounts[0] as string);
        this.isConnected$.next(true);
        // await this.loadusers                                                   <-------------------------------------
      }
    } catch (error) {
      console.error('User rejected connection:', error);
    }
  }

  // async loadusersescrow                                                        <------------------------------

}
