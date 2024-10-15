page 11002 "Data Exports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Data Exports';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Export';
    SourceTable = "Data Export";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for a data export.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the data export.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Export)
            {
                Caption = 'Export';
                action("Data Export Record Definition")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Definitions';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Data Export Record Definitions";
                    RunPageLink = "Data Export Code" = FIELD(Code);
                    RunPageView = SORTING("Data Export Code", "Data Exp. Rec. Type Code");
                    ToolTip = 'Add record definitions to the data export. Each record definition represents a set of data that will be exported.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DataExportManagement: Codeunit "Data Export Management";
    begin
        DataExportManagement.CreateDataExportForPersonalAndGLAccounting();
        DataExportManagement.CreateDataExportForFAAccounting();
        DataExportManagement.CreateDataExportForInvoiceAndItemAccounting();
    end;
}

