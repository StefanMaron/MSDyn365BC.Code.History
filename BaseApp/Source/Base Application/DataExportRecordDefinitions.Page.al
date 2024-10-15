page 11003 "Data Export Record Definitions"
{
    Caption = 'Data Export Record Definitions';
    DataCaptionFields = "Data Export Code";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Record Definition,DTD File';
    SourceTable = "Data Export Record Definition";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Data Export Code"; "Data Export Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data export that contains the record definition.';
                    Visible = false;
                }
                field("Data Exp. Rec. Type Code"; "Data Exp. Rec. Type Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the data export record definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the data export record definition.';
                }
                field("DTD File Name"; "DTD File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the DTD file that is required for digital audit.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Record Definition")
            {
                Caption = 'Record Definition';
                Image = XMLFile;
                action("Data Export Record Source")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Source';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Data Export Record Source";
                    RunPageLink = "Data Export Code" = FIELD("Data Export Code"),
                                  "Data Exp. Rec. Type Code" = FIELD("Data Exp. Rec. Type Code");
                    RunPageView = SORTING("Data Export Code", "Data Exp. Rec. Type Code", "Line No.");
                    ToolTip = 'View information about the tables for the a data export record definition.';
                }
                action(Validate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Test the specified data before you export it.';

                    trigger OnAction()
                    var
                        DataExportRecordDefinition: Record "Data Export Record Definition";
                    begin
                        DataExportRecordDefinition.Get("Data Export Code", "Data Exp. Rec. Type Code");
                        DataExportRecordDefinition.ValidateExportSources;
                    end;
                }
                action(Action1140010)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = ExportFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Send the specified data to a file.';

                    trigger OnAction()
                    var
                        DataExportRecordDefinition: Record "Data Export Record Definition";
                        ExportBusinessData: Report "Export Business Data";
                    begin
                        DataExportRecordDefinition.Reset;
                        DataExportRecordDefinition.SetRange("Data Export Code", "Data Export Code");
                        DataExportRecordDefinition.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
                        ExportBusinessData.SetTableView(DataExportRecordDefinition);
                        ExportBusinessData.Run;
                        Clear(ExportBusinessData);
                    end;
                }
            }
            group("DTD File")
            {
                Caption = 'DTD File';
                Image = XMLFile;
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Import a file with financial data and tax data according to the process for data access and testability of digital audit documents. ';

                    trigger OnAction()
                    begin
                        ImportFile(Rec);
                        CurrPage.Update;
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Send the specified data to a file.';

                    trigger OnAction()
                    begin
                        ExportFile(Rec, true);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MoveFiltersToFilterGroup(2);
    end;

    [Scope('OnPrem')]
    procedure MoveFiltersToFilterGroup(FilterGroupNo: Integer)
    var
        Filters: Text;
    begin
        FilterGroup(0);
        Filters := GetView;
        FilterGroup(FilterGroupNo);
        SetView(Filters);
        FilterGroup(0);
        SetView('');
    end;
}

