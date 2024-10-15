page 10510 "Check Preview GB"
{
    Caption = 'Check Preview GB';
    DataCaptionExpression = "Document No." + ' ' + CheckToAddr[1];
    Editable = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(Control11)
            {
                ShowCaption = false;
                field("UPPERCASE(CheckToAddr[1])"; UpperCase(CheckToAddr[1]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pay';
                    ToolTip = 'Specifies that you want to issue the check after you have seen how the check will look when it is printed on paper.';
                }
                field(AmountInText; NumberText[1])
                {
                    ApplicationArea = Basic, Suite;
                }
                field("NumberText[2]"; NumberText[2])
                {
                    ApplicationArea = Basic, Suite;
                }
                field(CheckStatusText; CheckStatusText)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(CheckDateText; CheckDateText)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(CheckAmountText; CheckAmountText)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcCheck;
    end;

    trigger OnOpenPage()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
    end;

    var
        Text000: Label 'Printed Check';
        Text001: Label 'Cheque Not Printed';
        GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        CheckReport: Report Check;
        FormatAddr: Codeunit "Format Address";
        CheckToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        NumberText: array[2] of Text[80];
        CheckStatusText: Text[30];
        CheckDateText: Text[30];
        CheckAmountText: Text[20];
        CheckAmount: Decimal;

    local procedure CalcCheck()
    begin
        if "Check Printed" then begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", "Posting Date");
            GenJnlLine.SetRange("Document No.", "Document No.");
            if "Bal. Account No." = '' then
                GenJnlLine.SetRange("Bank Payment Type", "Bank Payment Type"::" ")
            else
                GenJnlLine.SetRange("Bank Payment Type", "Bank Payment Type"::"Computer Check");
            GenJnlLine.SetRange("Check Printed", true);
            CheckStatusText := Text000;
        end else begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", "Posting Date");
            GenJnlLine.SetRange("Document No.", "Document No.");
            GenJnlLine.SetRange("Account Type", "Account Type");
            GenJnlLine.SetRange("Account No.", "Account No.");
            GenJnlLine.SetRange("Bal. Account Type", "Bal. Account Type");
            GenJnlLine.SetRange("Bal. Account No.", "Bal. Account No.");
            GenJnlLine.SetRange("Bank Payment Type", "Bank Payment Type");
            CheckStatusText := Text001;
        end;

        CheckAmount := 0;
        if GenJnlLine.Find('-') then
            repeat
                CheckAmount := CheckAmount + GenJnlLine.Amount;
            until GenJnlLine.Next() = 0;

        if CheckAmount < 0 then
            CheckAmount := 0;

        CheckReport.InitTextVariable;
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
            GenJnlLine."Account Type"::Vendor:
                begin
                    Vend.Get(GenJnlLine."Account No.");
                    Vend.Contact := '';
                    FormatAddr.Vendor(CheckToAddr, Vend);
                end;
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    BankAcc.Get(GenJnlLine."Account No.");
                    BankAcc.Contact := '';
                    FormatAddr.BankAcc(CheckToAddr, BankAcc);
                end;
            GenJnlLine."Account Type"::"Fixed Asset":
                GenJnlLine.FieldError("Account Type");
        end;

        CheckDateText := UpperCase(Format("Posting Date", 9, '<Day,2><Month Text,3><Year4>'));

        CheckAmountText := Format(CheckAmount, 0, '**<Sign><Integer>-<Decimals,3>**');
        CheckAmountText := DelChr(CheckAmountText, '=', '.');
    end;
}

