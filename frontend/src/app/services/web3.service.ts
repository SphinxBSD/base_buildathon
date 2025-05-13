import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { ethers } from 'ethers';

import VaultFactoryAbi from '../../../../artifacts/contracts/core/VaultFactory.sol/VaultFactory.json';
import SingleOwnerVaultAbi from '../../../../artifacts/contracts/core/VaultTypes/SingleOwnerVault.sol/SingleOwnerVault.json';

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
  private vaultFactoryContract: ethers.Contract | null = null;
  private vaultFactoryAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3'; // Replace with your deployed contract address

  public isConnected$ = new BehaviorSubject<boolean>(false);
  public account$ = new BehaviorSubject<string>('');
  public networkId$ = new BehaviorSubject<number>(0);
  public vaultContract$ = new BehaviorSubject<ethers.Contract | null>(null);

  constructor() {
    // No inicializamos automáticamente para dar control al usuario
    // Solo verificamos si hay una sesión guardada
    this.checkForSavedSession();
  }

  private checkForSavedSession(): void {
    // Comprobar si hay una sesión guardada en localStorage
    const savedAccount = localStorage.getItem('walletAddress');
    if (savedAccount) {
      // Si hay una cuenta guardada, intentaremos reconectar silenciosamente
      this.silentlyReconnect();
    }
  }

  private async silentlyReconnect(): Promise<void> {
    if (window.ethereum) {
      try {
        // Intenta obtener las cuentas sin pedir permiso al usuario
        const accounts = await window.ethereum.request({
          method: 'eth_accounts'  // No solicita aprobación, solo devuelve cuentas ya aprobadas
        });
        
        if (accounts && Array.isArray(accounts) && accounts.length > 0) {
          // Si tenemos acceso a una cuenta, inicializamos web3
          await this.initializeWeb3WithAccount(accounts[0] as string);
        }
      } catch (error) {
        console.error('Error reconectando silenciosamente:', error);
      }
    }
  }

  private async initializeWeb3WithAccount(account: string): Promise<void> {
    try {
      this.provider = new ethers.BrowserProvider(window.ethereum!);
      
      this.account$.next(account);
      
      // Get Signer
      this.signer = await this.provider.getSigner();

      // Obtener Id de la network
      const network = await this.provider.getNetwork();
      this.networkId$.next(Number(network.chainId));

      // Initialize contracts
      await this.initContracts();

      // Set up event listeners
      this.setupEventListeners();
      
      this.isConnected$.next(true);
      
      // Guardar en localStorage
      localStorage.setItem('walletAddress', account);
    } catch (error) {
      console.error('Error inicializando Web3 con cuenta:', error);
    }
  }

  private setupEventListeners(): void {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts: unknown) => {
        if (Array.isArray(accounts) && accounts.length > 0) {
          const account = accounts[0] as string;
          this.account$.next(account);
          localStorage.setItem('walletAddress', account);
        } else {
          this.disconnectWallet(); // Si se desconecta la cuenta desde MetaMask
        }
      });

      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      });

      window.ethereum.on('disconnect', () => {
        this.disconnectWallet();
      });
    }
  }

  async initWeb3(): Promise<void> {
    // Check if Metamask installed
    if (window.ethereum) {
      try {
        this.provider = new ethers.BrowserProvider(window.ethereum);

        // Solicitar el acceso a la cuenta
        const accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
        if (accounts && Array.isArray(accounts) && accounts.length > 0){
          const account = accounts[0] as string;
          this.account$.next(account);
          localStorage.setItem('walletAddress', account);
        }

        // Get Signer
        this.signer = await this.provider.getSigner();

        // Obtener Id de la network
        const network = await this.provider.getNetwork();
        this.networkId$.next(Number(network.chainId));

        // Initialize contracts
        await this.initContracts();

        // Set up event listeners
        this.setupEventListeners();
        
        this.isConnected$.next(true);
      } catch (error) {
        console.error('Error Initializing Web3', error);
      }
    } else {
      console.error('Please Install Metamask');
    }
  }

  private async initContracts(): Promise<void> {
    try {
      if (!this.signer) return;

      this.vaultFactoryContract = new ethers.Contract(
        this.vaultFactoryAddress,
        VaultFactoryAbi.abi,
        this.signer
      );
      
      this.vaultContract$.next(this.vaultFactoryContract);
    } catch (error) {
      console.error('Error initializing contracts:', error);
    }
  }

  async connectWallet(): Promise<void> {
    if (!this.provider) {
      await this.initWeb3();
      return;
    }

    try {
      const accounts = await window.ethereum?.request({ method: 'eth_requestAccounts'});
      if (accounts && Array.isArray(accounts) && accounts.length > 0) {
        const account = accounts[0] as string;
        this.account$.next(account);
        this.isConnected$.next(true);
        
        // Guardar en localStorage
        localStorage.setItem('walletAddress', account);
        
        // Initialize signer and contracts if not already done
        if (!this.signer) {
          this.signer = await this.provider.getSigner();
          await this.initContracts();
        }
      }
    } catch (error) {
      console.error('User rejected connection:', error);
    }
  }

  /**
   * Desconecta la wallet limpiando el estado y localStorage
   */
  disconnectWallet(): void {
    this.account$.next('');
    this.isConnected$.next(false);
    this.signer = null;
    
    // Eliminar del almacenamiento local
    localStorage.removeItem('walletAddress');
  }

  /**
   * Intenta reconectar con una wallet previamente conectada
   */
  async reconnectWallet(): Promise<void> {
    const savedAddress = localStorage.getItem('walletAddress');
    if (savedAddress && window.ethereum) {
      await this.silentlyReconnect();
    }
  }

  // Public getters
  getProvider(): ethers.BrowserProvider | null {
    return this.provider;
  }

  getSigner(): ethers.JsonRpcSigner | null {
    return this.signer;
  }

  getAccount(): string {
    return this.account$.getValue();
  }

  getNetworkId(): number {
    return this.networkId$.getValue();
  }

  getVaultFactoryContract(): ethers.Contract | null {
    return this.vaultFactoryContract;
  }

  isConnected(): boolean {
    return this.isConnected$.getValue();
  }

  // Observable getters
  getAccount$(): Observable<string> {
    return this.account$.asObservable();
  }

  getIsConnected$(): Observable<boolean> {
    return this.isConnected$.asObservable();
  }

  getNetworkId$(): Observable<number> {
    return this.networkId$.asObservable();
  }

  getVaultFactoryContract$(): Observable<ethers.Contract | null> {
    return this.vaultContract$.asObservable();
  }
}