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
  selector: 'app-withdraw-dialog',
  imports: [
    MatFormField,
    CommonModule,
    MatDialogActions,
    MatDialogContent,
    FormsModule
  ],
  templateUrl: './withdraw-dialog.component.html',
  styleUrl: './withdraw-dialog.component.scss'
})
export class WithdrawDialogComponent {
  recipient: string = '';
  amount: string = '';

  constructor(
    public dialogRef: MatDialogRef<WithdrawDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { vault: Vault },
    private vaultService: VaultService
  ) {}

  onWithdraw(): void {
    if (!this.recipient || !this.amount) return;
    this.vaultService.withdrawFromVault(this.data.vault.address, this.recipient, this.amount).subscribe(() => {
      this.dialogRef.close();
    });
  }
}
