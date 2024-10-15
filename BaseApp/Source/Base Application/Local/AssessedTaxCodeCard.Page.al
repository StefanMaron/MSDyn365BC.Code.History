page 14921 "Assessed Tax Code Card"
{
    Caption = 'Assessed Tax Code Card';
    PageType = Card;
    SourceTable = "Assessed Tax Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code number that represents an assessed fixed assets tax.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the assessed tax code.';
                }
                field("Region Code"; Rec."Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-character region code that is used with the Tax Authority No. field to determine the OKATO code.';
                }
                field("Rate %"; Rec."Rate %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax rate for this assessed fixed assets tax.';
                }
                field("Dec. Rate Tax Allowance Code"; Rec."Dec. Rate Tax Allowance Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the assessed tax allowance code that reduces the calculated assessed tax amount.';
                }
                field("Dec. Amount Tax Allowance Code"; Rec."Dec. Amount Tax Allowance Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of an assessed tax allowance.';
                }
                field("Decreasing Amount Type"; Rec."Decreasing Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the decreasing amount value is a percentage or an amount.';
                }
                field("Decreasing Amount"; Rec."Decreasing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value to be used in the assessed tax calculation if there is a tax allowance that reduces assessed taxes.';
                }
                field("Exemption Tax Allowance Code"; Rec."Exemption Tax Allowance Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an assessed tax allowance exemption.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordFound: Boolean;
    begin
        RecordFound := Find(Which);
        CurrPage.Editable := RecordFound or (GetFilter(Code) = '');
        exit(RecordFound);
    end;
}

