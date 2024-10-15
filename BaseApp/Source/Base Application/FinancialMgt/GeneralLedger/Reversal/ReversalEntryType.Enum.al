﻿namespace Microsoft.Finance.GeneralLedger.Reversal;

enum 180 "Reversal Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "G/L Account")
    {
        Caption = 'G/L Account';
    }
    value(2; "Customer")
    {
        Caption = 'Customer';
    }
    value(3; "Vendor")
    {
        Caption = 'Vendor';
    }
    value(4; "Bank Account")
    {
        Caption = 'Bank Account';
    }
    value(5; "Fixed Asset")
    {
        Caption = 'Fixed Asset';
    }
    value(6; "Maintenance")
    {
        Caption = 'Maintenance';
    }
    value(7; "VAT")
    {
        Caption = 'VAT';
    }
    value(8; "Employee")
    {
        Caption = 'Employee';
    }
}
