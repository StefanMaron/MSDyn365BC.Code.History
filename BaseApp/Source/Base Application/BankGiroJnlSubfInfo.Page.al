page 35001 "Bank/Giro Jnl. Subf. Info"
{
    Caption = 'Bank/Giro Jnl. Subf. Info';
    PageType = CardPart;
    SourceTable = "CBG Statement Line";

    layout
    {
        area(content)
        {
            field(AccountName; GetAccountName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Account Name';
                Editable = false;
                ToolTip = 'Specifies the name of the account the CBG statement is linked to.';
            }
            field(VATStatus; StrSubstNo('%1 %2%', "VAT Type", "VAT %"))
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CBGStatement.Currency;
                AutoFormatType = 2;
                Caption = 'VAT';
                Editable = false;
                ToolTip = 'Specifies the VAT percentage on the account for the CBG statement.';
            }
            field(StatusVATAmount; "Debit VAT" + "Credit VAT")
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CBGStatement.Currency;
                AutoFormatType = 1;
                Caption = 'VAT Amount';
                Editable = false;
                ToolTip = 'Specifies the VAT amount on the account for the CBG statement.';
            }
            field(TotalBalance; TotalNetChange(Text1000003))
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CBGStatement.Currency;
                AutoFormatType = 1;
                Caption = 'Total Debit';
                Editable = false;
                ToolTip = 'Specifies the total debit amount on the account for the CBG statement.';
            }
            field(TotalBalance2; TotalNetChange(Text1000002))
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CBGStatement.Currency;
                AutoFormatType = 1;
                Caption = 'Total Credit';
                Editable = false;
                ToolTip = 'Specifies the total credit amount on the account for the CBG statement.';
            }
            field(TotalBalance3; -TotalNetChange(Text1000001))
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CBGStatement.Currency;
                AutoFormatType = 1;
                Caption = 'Total Net Change';
                Editable = false;
                ToolTip = 'Specifies the net change on the account for the CBG statement.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetHeader;
    end;

    var
        CBGStatement: Record "CBG Statement";
        Text1000001: Label 'NCI';
        Text1000002: Label 'CI';
        Text1000003: Label 'DI';

    [Scope('OnPrem')]
    procedure GetHeader()
    var
        UseNumber: Integer;
        UseTemplate: Code[10];
    begin
        FilterGroup(4);
        UseTemplate := DelChr(GetFilter("Journal Template Name"), '<>', '''');
        Evaluate(UseNumber, '0' + GetFilter("No."));
        FilterGroup(0);

        if UseNumber <> 0 then
            if (CBGStatement."Journal Template Name" <> UseTemplate) or
               (CBGStatement."No." <> UseNumber)
            then
                CBGStatement.Get(UseTemplate, UseNumber);
    end;
}

