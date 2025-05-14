import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { Vault } from '../../models/vault.model';
import { VaultService } from '../../services/vault.service';
import { MatFormField } from '@angular/material/input';
import { CommonModule } from '@angular/common';
import { MatDialogActions } from '@angular/material/dialog';
import { MatDialogContent } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-deposit-dialog',
  imports: [
    MatFormField,
    CommonModule,
    MatDialogActions,
    MatDialogContent,
    FormsModule
  ],
  templateUrl: './deposit-dialog.component.html',
  styleUrl: './deposit-dialog.component.scss'
})
export class DepositDialogComponent {
  amount: string = '';

  constructor(
    public dialogRef: MatDialogRef<DepositDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { vault: Vault },
    private vaultService: VaultService
  ) {}

  onDeposit(): void {
    if (!this.amount || parseFloat(this.amount) <= 0) return;
    this.vaultService.depositToVault(this.data.vault.address, this.amount).subscribe(() => {
      this.dialogRef.close();
    });
  }
}
