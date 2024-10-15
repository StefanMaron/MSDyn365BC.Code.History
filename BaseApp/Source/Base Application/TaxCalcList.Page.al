page 17310 "Tax Calc. List"
{
    Caption = 'Tax Calc. List';
    CardPageID = "Tax Calc. Setup Card";
    DelayedInsert = true;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "Tax Calc. Header";

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation header.';
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID associated with the tax calculation header.';
                    Visible = TableIDVisible;
                }
                field("Storing Method"; "Storing Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the storing method associated with the tax calculation header.';
                    Visible = StoringMethodVisible;
                }
                field("Tax Diff. Code"; "Tax Diff. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences code associated with the tax calculation header.';
                }
                field("G/L Corr. Analysis View Code"; "G/L Corr. Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger corresponding analysis view code.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Data)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Data';
                Image = AccountingPeriods;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Tax Calc. Accumulation";
                RunPageLink = "Section Code" = FIELD("Section Code"),
                              "No." = FIELD("No.");
            }
        }
    }

    trigger OnInit()
    begin
        StoringMethodVisible := true;
        TableIDVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
        TableIDVisible := CurrPage.Editable;
        StoringMethodVisible := CurrPage.Editable;
    end;

    var
        [InDataSet]
        TableIDVisible: Boolean;
        [InDataSet]
        StoringMethodVisible: Boolean;
}

