page 740 "VAT Report"
{
    Caption = 'VAT Return';
    DataCaptionExpression = "No.";
    LinksAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,VAT Settlement';
    SourceTable = "VAT Report Header";
    SourceTableView = WHERE("VAT Report Config. Code" = CONST("VAT Return"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsEditable;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("VAT Report Version"; "VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Version';
                    Editable = NOT ReturnPeriodEnabled;
                    NotBlank = true;
                    ToolTip = 'Specifies version of the report.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';

                    trigger OnValidate()
                    begin
                        InitPageControllers;
                    end;
                }
                field("Amounts in Add. Rep. Currency"; "Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
                }
                field("Additional Information"; "Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the additional information must be added to VAT report.';
                    Visible = false;
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the VAT report lines were created.';
                    Visible = false;
                }
                group(Control23)
                {
                    Editable = false;
                    ShowCaption = false;
                    field("Period Year"; "Period Year")
                    {
                        ApplicationArea = Basic, Suite;
                        LookupPageID = "Date Lookup";
                        ToolTip = 'Specifies the year of the reporting period.';
                    }
                    field("Period Type"; "Period Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of the reporting period. The field is empty if a custom period is defined.';
                    }
                    field("Period No."; "Period No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the specific reporting period to use. The field is empty if a custom period is defined.';
                    }
                    field("Start Date"; "Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the first date of the reporting period.';
                    }
                    field("End Date"; "End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the last date of the reporting period.';
                    }
                }
            }
            group("Return Period")
            {
                Editable = false;
                Visible = ReturnPeriodEnabled;
                field(ReturnPeriodDueDate; ReturnPeriodDueDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(ReturnPeriodStatus; ReturnPeriodStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
            }
            part(VATReportLines; "VAT Report Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Lines';
                SubPageLink = "VAT Report No." = FIELD("No."),
                              "VAT Report Config. Code" = FIELD("VAT Report Config. Code");
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Messages';
                Visible = ErrorsExist;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Lines';
                    Enabled = SuggestLinesControllerStatus;
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Create VAT Report entries based on information gathered from documents related to sales and purchases. ';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
                        CurrPage.VATReportLines.PAGE.SelectFirst;
                        CheckForErrors;
                    end;
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Enabled = ReleaseControllerStatus;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Verify that the report includes all of the required information, and prepare it for submission.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                        CheckForErrors;
                    end;
                }
                action(Generate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generate';
                    Enabled = SubmitControllerStatus;
                    Image = GetLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Generate the content of VAT report.';
                    Visible = GenerationVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        if not CheckForErrors() then
                            Message(ReportGeneratedMsg);
                    end;
                }
                action(Submit)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Submit';
                    Enabled = SubmitControllerStatus;
                    Image = SendElectronicDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Submits the VAT report to the tax authority''s reporting service.';
                    Visible = SubmissionVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        if not CheckForErrors then
                            Message(ReportSubmittedMsg);
                    end;
                }
                action("Receive Response")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive Response';
                    Enabled = ReceiveControllerStatus;
                    Image = Alerts;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Receive a response from the the tax authority''s reporting service after the VAT report submission.';
                    Visible = ReceiveVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.ReceiveResponse(Rec);
                    end;
                }
                action("Mark as Submitted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Submitted';
                    Enabled = MarkAsSubmitControllerStatus;
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Indicate that you submitted the report to the tax authority manually.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                        if not CheckForErrors then
                            Message(MarkAsSubmittedMsg);
                    end;
                }
                action("Cancel Submission")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Submission';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Cancels previously submitted report.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                        Message(CancelReportSentMsg);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = ReopenControllerStatus;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
                action("Download Submission Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Submission Message';
                    Enabled = DownloadSubmissionControllerStatus;
                    Image = MoveDown;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    var
                        VATReportArchive: Record "VAT Report Archive";
                    begin
                        VATReportArchive.DownloadSubmissionMessage("VAT Report Config. Code", "No.");
                    end;
                }
                action("Download Response Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Response Message';
                    Enabled = DownloadResponseControllerStatus;
                    Image = MoveDown;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    var
                        VATReportArchive: Record "VAT Report Archive";
                    begin
                        VATReportArchive.DownloadResponseMessage("VAT Report Config. Code", "No.");
                    end;
                }
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate and Post VAT Settlement';
                    Enabled = CalcAndPostVATStatus;
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;

                    trigger OnAction()
                    var
                        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
                    begin
                        CalcAndPostVATSettlement.InitializeRequest("Start Date", "End Date", WorkDate, "No.", '', false, false);
                        CalcAndPostVATSettlement.Run;
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';
                Visible = false;

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
            }
            action("Report Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
        area(navigation)
        {
            action("Open VAT Return Period Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open VAT Return Period Card';
                Image = ShowList;
                ToolTip = 'Open the VAT return period card for this VAT return.';
                Visible = ReturnPeriodEnabled;

                trigger OnAction()
                var
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    VATReportMgt.OpenVATPeriodCardFromVATReturn(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InitPageControllers;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InitPageControllers;
    end;

    trigger OnOpenPage()
    begin
        if "No." <> '' then
            InitPageControllers;
        IsEditable := Status = Status::Open;
    end;

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        ErrorsExist: Boolean;
        ReportGeneratedMsg: Label 'The report has been successfully generated.';
        ReportSubmittedMsg: Label 'The report has been successfully submitted.';
        CancelReportSentMsg: Label 'The cancellation request has been sent.';
        MarkAsSubmittedMsg: Label 'The report has been marked as submitted.';
        SuggestLinesControllerStatus: Boolean;
        SubmitControllerStatus: Boolean;
        GenerationVisible: Boolean;
        SubmissionVisible: Boolean;
        ReceiveControllerStatus: Boolean;
        ReceiveVisible: Boolean;
        MarkAsSubmitControllerStatus: Boolean;
        ReleaseControllerStatus: Boolean;
        ReopenControllerStatus: Boolean;
        IsEditable: Boolean;
        DownloadSubmissionControllerStatus: Boolean;
        DownloadResponseControllerStatus: Boolean;
        CalcAndPostVATStatus: Boolean;
        ReturnPeriodDueDate: Date;
        ReturnPeriodStatus: Option Open,Closed;
        ReturnPeriodEnabled: Boolean;

    local procedure InitPageControllers()
    begin
        SuggestLinesControllerStatus := Status = Status::Open;
        ReleaseControllerStatus := Status = Status::Open;
        GenerationVisible := VATReportMediator.ShowGenerate(Rec);
        SubmissionVisible := VATReportMediator.ShowExport(Rec);
        SubmitControllerStatus := Status = Status::Released;
        ReceiveVisible := VATReportMediator.ShowReceiveResponse(Rec);
        ReceiveControllerStatus := Status = Status::Submitted;
        MarkAsSubmitControllerStatus := Status = Status::Released;
        DownloadSubmissionControllerStatus := VATReportMediator.ShowSubmissionMessage(Rec);
        DownloadResponseControllerStatus := (Status = Status::Rejected) or
          (Status = Status::Accepted) or
          (Status = Status::Closed);
        CalcAndPostVATStatus := Status = Status::Accepted;
        ReopenControllerStatus := Status = Status::Released;
        InitReturnPeriodGroup;
        OnAfterInitPageControllers(Rec, SubmitControllerStatus, MarkAsSubmitControllerStatus);
    end;

    local procedure InitReturnPeriodGroup()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        ReturnPeriodEnabled := VATReturnPeriod.Get("Return Period No.");
        if ReturnPeriodEnabled then begin
            ReturnPeriodDueDate := VATReturnPeriod."Due Date";
            ReturnPeriodStatus := VATReturnPeriod.Status;
        end;
    end;

    local procedure CheckForErrors(): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.CopyFromContext(Rec);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update;
        ErrorsExist := not TempErrorMessage.IsEmpty;

        exit(ErrorsExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPageControllers(VATReportHeader: Record "VAT Report Header"; var SubmitControllerStatus: Boolean; var MarkAsSubmitControllerStatus: Boolean)
    begin
    end;
}

