page 12150 "VAT Register Reprinting Info."
{
    Caption = 'VAT Register Reprinting Information';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Reprint Info Fiscal Reports";
    SourceTableView = WHERE(Report = CONST("VAT Register - Print"));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the start date that is associated with the printed fiscal report.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the end date that is associated with the printed fiscal report.';
                }
                field("Vat Register Code"; Rec."Vat Register Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the identification code of the VAT register that is associated with the printed fiscal report.';
                }
                field("First Page Number"; Rec."First Page Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page number of the first page of the fiscal report.';
                }
            }
        }
    }

    actions
    {
    }
}

