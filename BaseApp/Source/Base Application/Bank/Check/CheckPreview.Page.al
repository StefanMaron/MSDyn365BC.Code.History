namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 404 "Check Preview"
{
    Caption = 'Check Preview';
    DataCaptionExpression = Rec."Document No." + ' ' + CheckToAddr[1];
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(Payer)
            {
                Caption = 'Payer';
                field("CompanyAddr[1]"; CompanyAddr[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company name that will appear on the check.';
                }
                field("CompanyAddr[2]"; CompanyAddr[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Address';
                    ToolTip = 'Specifies the company address that will appear on the check.';
                }
                field("CompanyAddr[3]"; CompanyAddr[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Address 2';
                    ToolTip = 'Specifies the extended company address that will appear on the check.';
                }
                field("CompanyAddr[4]"; CompanyAddr[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Post Code/City';
                    ToolTip = 'Specifies the company post code and city that will appear on the check.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field(CheckStatusText; CheckStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies if the check is printed.';
                }
            }
            group(Amount)
            {
                Caption = 'Amount';
                group(Control30)
                {
                    ShowCaption = false;
                    label(AmountText)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(NumberText[1]);
                        Caption = 'Amount Text';
                        ToolTip = 'Specifies the amount in letters that will appear on the check.';
                    }
                    label("Amount Text 2")
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(NumberText[2]);
                        Caption = 'Amount Text 2';
                        ToolTip = 'Specifies an additional part of the amount in letters that will appear on the check.';
                    }
                }
            }
            group(Payee)
            {
                Caption = 'Payee';
                fixed(Control1902115401)
                {
                    ShowCaption = false;
                    group("Pay to the order of")
                    {
                        Caption = 'Pay to the order of';
                        field("CheckToAddr[1]"; CheckToAddr[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay-to Name';
                            ToolTip = 'Specifies the name of the payee that will appear on the check.';
                        }
                        field("CheckToAddr[2]"; CheckToAddr[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay-to Address';
                            ToolTip = 'Specifies the address of the payee that will appear on the check.';
                        }
                        field("CheckToAddr[3]"; CheckToAddr[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay-to Address 2';
                            ToolTip = 'Specifies the extended address of the payee that will appear on the check.';
                        }
                        field("CheckToAddr[4]"; CheckToAddr[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay-to Post Code/City';
                            ToolTip = 'Specifies the post code and city of the payee that will appear on the check.';
                        }
                    }
                    group(Date)
                    {
                        Caption = 'Date';
                        field("Posting Date"; Rec."Posting Date")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the posting date for the entry.';
                        }
                        field(Text002; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder2; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder3; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                    group(Control1900724401)
                    {
                        Caption = 'Amount';
                        field(CheckAmount; CheckAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ShowCaption = false;
                            ToolTip = 'Specifies the amount that will appear on the check.';
                        }
                        field(Placeholder4; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder5; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder6; Text002)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcCheck();
    end;

    trigger OnOpenPage()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        Employee: Record Employee;
        CheckReport: Report Check;
        FormatAddr: Codeunit "Format Address";
        CheckToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        NumberText: array[2] of Text[80];
        CheckStatusText: Text[30];
        CheckAmount: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Printed Check';
        Text001: Label 'Not Printed Check';
        Text002: Label 'Placeholder';
#pragma warning restore AA0074

    local procedure CalcCheck()
    begin
        if Rec."Check Printed" then begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", Rec."Posting Date");
            GenJnlLine.SetRange("Document No.", Rec."Document No.");
            if Rec."Bal. Account No." = '' then
                GenJnlLine.SetRange("Bank Payment Type", GenJnlLine."Bank Payment Type"::" ")
            else
                GenJnlLine.SetRange("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Computer Check");
            GenJnlLine.SetRange("Check Printed", true);
            CheckStatusText := Text000;
        end else begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", Rec."Posting Date");
            GenJnlLine.SetRange("Document No.", Rec."Document No.");
            GenJnlLine.SetRange("Account Type", Rec."Account Type");
            GenJnlLine.SetRange("Account No.", Rec."Account No.");
            GenJnlLine.SetRange("Bal. Account Type", Rec."Bal. Account Type");
            GenJnlLine.SetRange("Bal. Account No.", Rec."Bal. Account No.");
            GenJnlLine.SetRange("Bank Payment Type", Rec."Bank Payment Type");
            CheckStatusText := Text001;
        end;

        CheckAmount := 0;
        if GenJnlLine.Find('-') then
            repeat
                CheckAmount := CheckAmount + GenJnlLine.Amount;
            until GenJnlLine.Next() = 0;

        if CheckAmount < 0 then
            CheckAmount := 0;

        FormatTextFieldsForCheck();
    end;

    local procedure FormatTextFieldsForCheck()
    var
        RemitAddress: Record "Remit Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatTextFieldsForCheck(CheckToAddr, CheckAmount, GenJnlLine, Cust, BankAcc, Employee, Vend, Rec, IsHandled);
        if IsHandled then
            exit;

        CheckReport.InitTextVariable();
        CheckReport.FormatNoText(NumberText, CheckAmount, GenJnlLine."Currency Code");

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                begin
                    Clear(CheckToAddr);
                    CheckToAddr[1] := GenJnlLine.Description;
                end;
            GenJnlLine."Account Type"::Customer:
                begin
                    Cust.Get(GenJnlLine."Account No.");
                    Cust.Contact := '';
                    FormatAddr.Customer(CheckToAddr, Cust);
                end;
#pragma warning disable AA0005
            GenJnlLine."Account Type"::Vendor:
                begin
                    if GenJnlLine."Remit-to Code" = '' then begin
                        Vend.Get(GenJnlLine."Account No.");
                        Vend.Contact := '';
                        FormatAddr.Vendor(CheckToAddr, Vend);
                    end
                    else begin
                        Vend.Get(GenJnlLine."Account No.");
                        RemitAddress.Get(GenJnlLine."Remit-to Code", GenJnlLine."Account No.");
                        FormatAddr.VendorRemitToAddress(RemitAddress, CheckToAddr);
                    end;
                end;
#pragma warning restore AA0005
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    BankAcc.Get(GenJnlLine."Account No.");
                    BankAcc.Contact := '';
                    FormatAddr.BankAcc(CheckToAddr, BankAcc);
                end;
            GenJnlLine."Account Type"::"Fixed Asset":
                GenJnlLine.FieldError("Account Type");
            GenJnlLine."Account Type"::Employee:
                begin
                    Employee.Get(GenJnlLine."Account No.");
                    FormatAddr.Employee(CheckToAddr, Employee);
                end;
        end;

        OnAfterFormatTextFieldsForCheck(CheckToAddr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatTextFieldsForCheck(var CheckToAddr: array[8] of Text[100]; CheckAmount: Decimal; var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; var BankAccount: Record "Bank Account"; var Employee: Record Employee; var Vendor: Record Vendor; Rec: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFormatTextFieldsForCheck(var CheckToAddr: array[8] of Text[100])
    begin
    end;
}

