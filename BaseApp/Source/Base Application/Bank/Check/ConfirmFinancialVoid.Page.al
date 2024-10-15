namespace Microsoft.Bank.Check;

page 695 "Confirm Financial Void"
{
    Caption = 'Confirm Financial Void';
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            label(Control19)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(Text002);
                Editable = false;
                ShowCaption = false;
            }
            field(VoidDate; VoidDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Void Date';
                ToolTip = 'Specifies the date that the void entry will be posted regardless of the void type that is selected. All of the unapply postings will also use the Void Date, if the Unapply and Void Check type is selected.';

                trigger OnValidate()
                begin
                    if VoidDate < CheckLedgerEntry."Check Date" then
                        Error(Text000, CheckLedgerEntry.FieldCaption("Check Date"));
                end;
            }
            field(VoidType; VoidType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Type of Void';
                OptionCaption = 'Unapply and void check,Void check only';
                ToolTip = 'Specifies how checks are voided. Unapply and Void Check: The payment will be unapplied so that the vendor ledger entry for the invoice will be open, and the payment will be reversed by the voided check. Void Check Only: The vendor ledger entry will still be closed by the payment entry, and the voided check entry will be open.';
            }
            group(Details)
            {
                Caption = 'Details';
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Bank Account No."""; CheckLedgerEntry."Bank Account No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the bank account.';
                }
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Check No."""; CheckLedgerEntry."Check No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check No.';
                    Editable = false;
                    ToolTip = 'Specifies the check number to be voided.';
                }
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Bal. Account No."""; CheckLedgerEntry."Bal. Account No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text001, CheckLedgerEntry."Bal. Account Type"));
                    Editable = false;
                }
                field("CheckLedgerEntry.Amount"; CheckLedgerEntry.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount to be voided.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        OnBeforeOnOpenPage(CheckLedgerEntry, VoidDate);

        VoidDate := CheckLedgerEntry."Check Date";
        if CheckLedgerEntry."Bal. Account Type" in [CheckLedgerEntry."Bal. Account Type"::Vendor, CheckLedgerEntry."Bal. Account Type"::Customer, CheckLedgerEntry."Bal. Account Type"::Employee] then
            VoidType := VoidType::"Unapply and void check"
        else
            VoidType := VoidType::"Void check only";
    end;

    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        VoidDate: Date;
        VoidType: Option "Unapply and void check","Void check only";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Void Date must not be before the original %1.';
        Text001: Label '%1 No.';
#pragma warning restore AA0470
        Text002: Label 'Do you want to void this check?';
#pragma warning restore AA0074

    procedure SetCheckLedgerEntry(var NewCheckLedgerEntry: Record "Check Ledger Entry")
    begin
        CheckLedgerEntry := NewCheckLedgerEntry;
    end;

    procedure GetVoidDate(): Date
    begin
        exit(VoidDate);
    end;

    procedure GetVoidType(): Integer
    begin
        exit(VoidType);
    end;

    procedure InitializeRequest(VoidCheckdate: Date; VoiceCheckType: Option)
    begin
        VoidDate := VoidCheckdate;
        VoidType := VoiceCheckType;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;
}

