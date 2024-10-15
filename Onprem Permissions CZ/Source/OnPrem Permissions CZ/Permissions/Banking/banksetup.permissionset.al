permissionset 11702 "BANK-SETUP"
{
    Access = Public;
    Assignable = true;
    Caption = 'Bank Acc., Operation Setup';

    Permissions = tabledata "Bank Account" = RIMD,
                  tabledata "Bank Export/Import Setup" = RIMD,
                  tabledata "Bank Pmt. Appl. Rule Code" = RIMD,
                  tabledata "Text-to-Account Mapping Code" = RIMD;
}
