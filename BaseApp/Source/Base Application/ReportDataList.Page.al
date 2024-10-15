page 26562 "Report Data List"
{
    Caption = 'Report Data List';
    CardPageID = "Report Data Card";
    DataCaptionFields = "Report Code";
    Editable = false;
    PageType = List;
    SourceTable = "Statutory Report Data Header";

    layout
    {
        area(content)
        {
            repeater(Control1470000)
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
                    ToolTip = 'Specifies the description of the statutory report data header information.';
                }
                field("Date Filter"; "Date Filter")
                {
                    ToolTip = 'Specifies the data filter of the statutory report data header.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the statutory report data header.';
                }
                field(Period; Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of the statutory report data header.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was created.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field(OKEI; OKEI)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure for amounts that are associated with the statutory report data header.';
                }
                field("Correction Number"; "Correction Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the correction number of the statutory report data header.';
                }
                field("No. in Year"; "No. in Year")
                {
                    ToolTip = 'Specifies the number in year associated with the statutory report data header.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
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
        area(navigation)
        {
            group("&Electronic &File")
            {
                Caption = '&Electronic &File';
                action("Create preview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create preview';
                    Image = PreviewChecks;

                    trigger OnAction()
                    begin
                        TestField(Status, Status::Open);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Overview';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Statutory Report Data Overview";
                RunPageLink = "No." = FIELD("No."),
                              "Report Code" = FIELD("Report Code");
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Export to &Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to &Excel';
                    Image = ExportToExcel;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        StatutoryReportDataHeader: Record "Statutory Report Data Header";
                    begin
                        StatutoryReportDataHeader := Rec;
                        StatutoryReportDataHeader.ExportResultsToExcel;
                    end;
                }
                action("Export Electronic &File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Electronic &File';
                    Ellipsis = true;
                    Image = InsertStartingFee;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        ExportResultsToXML;
                    end;
                }
                separator(Action1210009)
                {
                }
                action(CheckXml)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Check XML';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        CheckXML;
                    end;
                }
                separator(Action1210025)
                {
                }
                action("&Update Report Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Update Report Data';
                    Image = Refresh;

                    trigger OnAction()
                    begin
                        UpdateData;
                    end;
                }
                separator(Action1210028)
                {
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    begin
                        StatutoryReportMgt.ReleaseDataHeader(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        StatutoryReportMgt.ReopenDataHeader(Rec);
                    end;
                }
            }
        }
    }

    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportMgt: Codeunit "Statutory Report Management";
}

