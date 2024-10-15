page 323 "ECSL Report List"
{
    ApplicationArea = VAT;
    Caption = 'ECSL Report List';
    CardPageID = "ECSL Report";
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    SourceTableView = WHERE("VAT Report Config. Code" = FILTER(VIES));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("VAT Report Config. Code"; "VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the appropriate configuration code for EC Sales List Reports.';
                    Visible = false;
                }
                field("VAT Report Type"; "VAT Report Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                    Visible = false;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the first date of the reporting period.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the last date of the EC sales list report.';
                }
                field(Status; Status)
                {
                    ApplicationArea = VAT;
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Original Report No."; "Original Report No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the original report.';
                }
                field("Report Period Type"; "Report Period Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the length of the reporting period.';
                }
                field("Report Period No."; "Report Period No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the EC sales list reporting period to use.';
                }
                field("Report Year"; "Report Year")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the year of the reporting period.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the ECSL report.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = VAT;
                Caption = 'Report Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
            }
        }
    }
}

