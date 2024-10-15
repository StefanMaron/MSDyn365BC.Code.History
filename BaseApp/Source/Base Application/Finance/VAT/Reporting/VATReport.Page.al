﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Attachment;
using System.DateTime;
using System.Utilities;

page 740 "VAT Report"
{
    Caption = 'BAS Report';
    DataCaptionExpression = Rec."No.";
    LinksAllowed = false;
    PageType = Document;
    SourceTable = "VAT Report Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsEditable;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("VAT Report Version"; Rec."VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Version';
                    Editable = not ReturnPeriodEnabled;
                    NotBlank = true;
                    ToolTip = 'Specifies version of the report.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';

                    trigger OnValidate()
                    begin
                        InitPageControllers();
                    end;
                }
                field("Amounts in Add. Rep. Currency"; Rec."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the additional information must be added to VAT report.';
                    Visible = false;
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the VAT report lines were created.';
                    Visible = false;
                }
                field(BASIdNoCtrl; Rec."BAS ID No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS ID No.';
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the BAS document number that is provided by the Australian Tax Office (ATO).';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BASCalculationSheet: Record "BAS Calculation Sheet";
                    begin
                        BASCalculationSheet.Reset();
                        if PAGE.RunModal(0, BASCalculationSheet, BASCalculationSheet.A1) = ACTION::LookupOK then begin
                            Rec."BAS ID No." := BASCalculationSheet.A1;
                            Rec."BAS Version No." := BASCalculationSheet."BAS Version";
                            Rec."Start Date" := BASCalculationSheet.A3;
                            Rec."End Date" := BASCalculationSheet.A4;
                        end;
                    end;
                }
                field(BASVersionNoCtrl; Rec."BAS Version No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Version';
                    Importance = Additional;
                    ToolTip = 'Specifies the version number of the BAS document.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BASCalculationSheet: Record "BAS Calculation Sheet";
                    begin
                        BASCalculationSheet.SetRange(A1, Rec."BAS ID No.");
                        if PAGE.RunModal(0, BASCalculationSheet, BASCalculationSheet."BAS Version") = ACTION::LookupOK then
                            Rec."BAS Version No." := BASCalculationSheet."BAS Version";
                    end;
                }
                group(Control23)
                {
                    Editable = false;
                    ShowCaption = false;
                    field("Period Year"; Rec."Period Year")
                    {
                        ApplicationArea = Basic, Suite;
                        LookupPageID = "Date Lookup";
                        ToolTip = 'Specifies the year of the reporting period.';
                        Visible = false;
                    }
                    field("Period Type"; Rec."Period Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of the reporting period. The field is empty if a custom period is defined.';
                        Visible = false;
                    }
                    field("Period No."; Rec."Period No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the specific reporting period to use. The field is empty if a custom period is defined.';
                        Visible = false;
                    }
                    field("Start Date"; Rec."Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the first date of the reporting period.';
                    }
                    field("End Date"; Rec."End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the last date of the reporting period.';
                    }
                    field("Statement Template Name"; Rec."Statement Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the VAT statement that was used to generate the VAT report.';
                    }
                    field("Statement Name"; Rec."Statement Name")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the VAT statement that was used to generate the VAT report.';
                    }
                    field("Settlement Posted"; Rec."Settlement Posted")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether a settlement has been posted for this report.';
                    }
                    field("Include Prev. Open Entries"; Rec."Include Prev. Open Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether the report includes open entries before the specified period.';
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
                Enabled = IsEnable;
                SubPageLink = "VAT Report No." = field("No."),
                              "VAT Report Config. Code" = field("VAT Report Config. Code");
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Messages';
                Visible = ErrorsExist;
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"),
                              "No." = field("No."),
                              "VAT Report Config. Code" = field("VAT Report Config. Code");
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
                    ToolTip = 'Create VAT Report entries based on information gathered from documents related to sales and purchases. ';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
                        CurrPage.VATReportLines.PAGE.SelectFirst();
                        CheckForErrors();
                    end;
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Enabled = ReleaseControllerStatus;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Verify that the report includes all of the required information, and prepare it for submission.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                        CheckForErrors();
                    end;
                }
                action(Generate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generate';
                    Enabled = SubmitControllerStatus;
                    Image = GetLines;
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
                    ToolTip = 'Submits the VAT report to the tax authority''s reporting service.';
                    Visible = SubmissionVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        if not CheckForErrors() then
                            Message(ReportSubmittedMsg);
                    end;
                }
                action("Receive Response")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive Response';
                    Enabled = ReceiveControllerStatus;
                    Image = Alerts;
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
                    ToolTip = 'Indicate that you submitted the report to the tax authority manually.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                        if not CheckForErrors() then
                            Message(MarkAsSubmittedMsg);
                    end;
                }
                action("Cancel Submission")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Submission';
                    Image = Cancel;
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
                        VATReportArchive.DownloadSubmissionMessage(Rec."VAT Report Config. Code".AsInteger(), Rec."No.");
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
                        VATReportArchive.DownloadResponseMessage(Rec."VAT Report Config. Code".AsInteger(), Rec."No.");
                    end;
                }
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate and Post VAT Settlement';
                    Enabled = CalcAndPostVATStatus;
                    Image = "Report";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';

                    trigger OnAction()
                    var
                        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
                    begin
                        if Rec."Include Prev. Open Entries" then
                            CalcAndPostVATSettlement.InitializeRequest(0D, Rec."End Date", WorkDate(), Rec."No.", '', false, false)
                        else
                            CalcAndPostVATSettlement.InitializeRequest(Rec."Start Date", Rec."End Date", WorkDate(), Rec."No.", '', false, false);
                        CalcAndPostVATSettlement.SetVATReport(Rec);
                        CalcAndPostVATSettlement.SetRequestOptionEditable(not VATReportMediator.DisableCalcAndPostVATTSettlementFields(Rec));
                        CalcAndPostVATSettlement.Run();
                        CurrPage.Update();
                    end;
                }
                action("GST Purchase Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Purchase Entries';
                    Image = VATEntries;
                    RunObject = Page "GST Purchase Entries";
                    ToolTip = 'View purchase transactions with goods and services tax (GST).';
                }
                action("GST Sales Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Sales Entries';
                    Image = VATEntries;
                    RunObject = Page "GST Sales Entries";
                    ToolTip = 'View sales transactions with goods and services tax (GST).';
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
                group(Category_Release)
                {
                    Caption = 'Release';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref(Submit_Promoted; Submit)
                {
                }
                actionref("Mark as Submitted_Promoted"; "Mark as Submitted")
                {
                }
                actionref(Generate_Promoted; Generate)
                {
                }
                actionref("Receive Response_Promoted"; "Receive Response")
                {
                }
                actionref("Cancel Submission_Promoted"; "Cancel Submission")
                {
                }
#if not CLEAN22
                actionref(Print_Promoted; Print)
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action is being demoted based on overall low usage.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Category4)
            {
                Caption = 'VAT Settlement', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Calc. and Post VAT Settlement_Promoted"; "Calc. and Post VAT Settlement")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InitPageControllers();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InitPageControllers();
    end;

    trigger OnOpenPage()
    var
        BASManagement: Codeunit "BAS Management";
    begin
        if Rec."No." <> '' then
            InitPageControllers();
        IsEditable := Rec.Status = Rec.Status::Open;
        IsEnable := BASManagement.VATReportChangesAllowed(Rec);
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
        IsEnable: Boolean;
        DownloadSubmissionControllerStatus: Boolean;
        DownloadResponseControllerStatus: Boolean;
        CalcAndPostVATStatus: Boolean;
        ReturnPeriodDueDate: Date;
        ReturnPeriodStatus: Option Open,Closed;
        ReturnPeriodEnabled: Boolean;

    local procedure InitPageControllers()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        SuggestLinesControllerStatus := Rec.Status = Rec.Status::Open;
        ReleaseControllerStatus := Rec.Status = Rec.Status::Open;
        GenerationVisible := VATReportMediator.ShowGenerate(Rec);
        SubmissionVisible := not VATReportMediator.DisableSubmitAction(Rec);
        SubmitControllerStatus := Rec.Status = Rec.Status::Released;
        ReceiveVisible := VATReportMediator.ShowReceiveResponse(Rec);
        ReceiveControllerStatus := Rec.Status = Rec.Status::Submitted;
        MarkAsSubmitControllerStatus := Rec.Status = Rec.Status::Released;
        DownloadSubmissionControllerStatus := VATReportMediator.ShowSubmissionMessage(Rec);
        DownloadResponseControllerStatus :=
          DocumentAttachment.VATReturnResponseAttachmentsExist(Rec) or
          (Rec.Status = Rec.Status::Rejected) or
          (Rec.Status = Rec.Status::Accepted) or
          (Rec.Status = Rec.Status::Closed);

        CalcAndPostVATStatus := VATReportMediator.AllowedToCalcAndPostVATSettlement(Rec);
        ReopenControllerStatus := Rec.Status = Rec.Status::Released;
        InitReturnPeriodGroup();
        OnAfterInitPageControllers(Rec, SubmitControllerStatus, MarkAsSubmitControllerStatus, CalcAndPostVATStatus);
    end;

    local procedure InitReturnPeriodGroup()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        ReturnPeriodEnabled := VATReturnPeriod.Get(Rec."Return Period No.");
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
        CurrPage.ErrorMessagesPart.PAGE.Update();
        ErrorsExist := not TempErrorMessage.IsEmpty();

        exit(ErrorsExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPageControllers(VATReportHeader: Record "VAT Report Header"; var SubmitControllerStatus: Boolean; var MarkAsSubmitControllerStatus: Boolean; var CalcAndPostVATStatus: Boolean)
    begin
    end;
}

