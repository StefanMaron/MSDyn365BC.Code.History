report 11740 "Cash Inventory"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CashInventory.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Inventory (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Currency Nominal Value"; "Currency Nominal Value")
        {
            DataItemTableView = SORTING("Currency Code", Value) ORDER(Descending);
            column(Cash_Denominator_Value; Value)
            {
                IncludeCaption = true;
            }
            column(Variables_ReportFilter; ReportFilter)
            {
            }
            column(Variables_Qty; Qty)
            {
            }
            column(Variables_Total; Total)
            {
            }
            column(Variables_PrintCurrCode; PrintCurrCode)
            {
            }
            column(Variables_Balance; Balance)
            {
            }
            column(Variables_ShowBalance; ShowBalance)
            {
            }
            column(Variables_Text001; Text001)
            {
            }
            column(Variables_Text002; Text002)
            {
            }
            column(System_CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }

            trigger OnAfterGetRecord()
            begin
                i += 1;
                Qty := DenQty[i];
                Total := Qty * DenValue[i];
            end;

            trigger OnPreDataItem()
            begin
                if CashDeskNo = '' then
                    Error(Text004);

                if Date = 0D then
                    Error(Text003);

                BankAccount.Get(CashDeskNo);
                ReportFilter := StrSubstNo(Text000, BankAccount.Name, BankAccount."Currency Code", Format(Date));

                SetRange("Currency Code", BankAccount."Currency Code");
                if BankAccount."Currency Code" = '' then
                    PrintCurrCode := GLSetup."LCY Code"
                else
                    PrintCurrCode := BankAccount."Currency Code";

                Clear(Total);
                if ShowBalance then begin
                    BankAccount.SetFilter("Date Filter", '..%1', Date);
                    Balance := BankAccount.CalcBalance;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(CashDeskNo; CashDeskNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Desk No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies number of cash desk.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            BankAccount."No." := CashDeskNo;
                            if PAGE.RunModal(PAGE::"Cash Desk List", BankAccount) = ACTION::LookupOK then begin
                                CashDeskNo := BankAccount."No.";
                                Refresh;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            CheckCashDeskNo(CashDeskNo);
                            Refresh;
                        end;
                    }
                    field(Date; Date)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                        ToolTip = 'Specifies the date of cash inventory.';
                    }
                    field(ShowBalance; ShowBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Statistics';
                        ToolTip = 'Specifies when the statistics is to be show';
                    }
                }
                group(Denominators)
                {
                    Caption = 'Denominators';
                    grid(Control1000000017)
                    {
                        GridLayout = Columns;
                        ShowCaption = false;
                        group(Control1000000006)
                        {
                            ShowCaption = false;
                            field("DenValue[1]"; DenValue[1])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Caption = 'Value';
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[2]"; DenValue[2])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[3]"; DenValue[3])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[4]"; DenValue[4])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[5]"; DenValue[5])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[6]"; DenValue[6])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[7]"; DenValue[7])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[8]"; DenValue[8])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[9]"; DenValue[9])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[10]"; DenValue[10])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                        }
                        group(Control1000000013)
                        {
                            ShowCaption = false;
                            field("DenQty[1]"; DenQty[1])
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Quantity';
                                Editable = FieldsNo >= 1;
                                ToolTip = 'Specifies quantity by value';
                            }
                            field("DenQty[2]"; DenQty[2])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 2;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[3]"; DenQty[3])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 3;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[4]"; DenQty[4])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 4;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[5]"; DenQty[5])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 5;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[6]"; DenQty[6])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 6;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[7]"; DenQty[7])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 7;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[8]"; DenQty[8])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 8;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[9]"; DenQty[9])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 9;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[10]"; DenQty[10])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 10;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                        }
                        group(Control1000000030)
                        {
                            ShowCaption = false;
                            field("DenValue[11]"; DenValue[11])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Caption = 'Value';
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[12]"; DenValue[12])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[13]"; DenValue[13])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[14]"; DenValue[14])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[15]"; DenValue[15])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[16]"; DenValue[16])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[17]"; DenValue[17])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[18]"; DenValue[18])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[19]"; DenValue[19])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                            field("DenValue[20]"; DenValue[20])
                            {
                                ApplicationArea = Basic, Suite;
                                BlankZero = true;
                                Editable = false;
                                ToolTip = 'Specifies usable value for currency.';
                            }
                        }
                        group(Control1000000024)
                        {
                            ShowCaption = false;
                            field("DenQty[11]"; DenQty[11])
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Quantity';
                                Editable = FieldsNo >= 11;
                                ToolTip = 'Specifies quantity by value';
                            }
                            field("DenQty[12]"; DenQty[12])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 12;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[13]"; DenQty[13])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 13;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[14]"; DenQty[14])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 14;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[15]"; DenQty[15])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 15;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[16]"; DenQty[16])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 16;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[17]"; DenQty[17])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 17;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[18]"; DenQty[18])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 18;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[19]"; DenQty[19])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 19;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                            field("DenQty[20]"; DenQty[20])
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = FieldsNo >= 20;
                                ToolTip = 'Specifies the quantity of specified nominal value.';
                            }
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Date := WorkDate;
            Refresh;
        end;
    }

    labels
    {
        Label_Report_Name = 'Cash Dissection';
        Label_Page = 'Page No.';
        Label_Qty = 'Quantity';
        Label_Total = 'Amount';
        Label_Commision = 'Comission:';
        Label_Date = 'Date:';
        Label_Cash_Balance = 'CASH BALANCE';
        Label_Account_Statistics = 'ACCOUNT STATISTICS';
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
        Date: Date;
        ReportFilter: Text[250];
        Total: Decimal;
        DenValue: array[20] of Decimal;
        i: Integer;
        DenQty: array[20] of Integer;
        Qty: Integer;
        PrintCurrCode: Code[10];
        ShowBalance: Boolean;
        Balance: Decimal;
        CashDeskNo: Code[20];
        [InDataSet]
        FieldsNo: Integer;
        Text000: Label '%1, %2 to %3';
        Text001: Label 'CASH DEFICIT';
        Text002: Label 'CASH OVER';
        Text003: Label 'Date cannot be empty.';
        Text004: Label 'Cash Desk No. cannot be empty.';

    [Scope('OnPrem')]
    procedure SetParameters(NewCashDeskNo: Code[20])
    begin
        CashDeskNo := NewCashDeskNo;
    end;

    [Scope('OnPrem')]
    procedure Refresh()
    var
        CurrNominalValue: Record "Currency Nominal Value";
        BankAccount2: Record "Bank Account";
    begin
        Clear(DenValue);
        Clear(DenQty);
        FieldsNo := 1;

        if BankAccount2.Get(CashDeskNo) then begin
            CurrNominalValue.Ascending(false);
            CurrNominalValue.SetRange("Currency Code", BankAccount2."Currency Code");
            CurrNominalValue.FindSet;
            repeat
                DenValue[FieldsNo] := CurrNominalValue.Value;
                DenQty[FieldsNo] := 0;
                FieldsNo += 1;
            until (CurrNominalValue.Next = 0) or (FieldsNo > 20);
        end;

        FieldsNo -= 1;
    end;

    local procedure CheckCashDeskNo(CashDeskNo: Code[20])
    var
        CashDeskManagement: Codeunit CashDeskManagement;
    begin
        CashDeskManagement.CheckCashDesk(CashDeskNo);
    end;
}

