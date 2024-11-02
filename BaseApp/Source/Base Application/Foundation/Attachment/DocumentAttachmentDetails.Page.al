// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

using Microsoft.CRM.Outlook;
using System.Integration;
using System.IO;
using System.Utilities;

page 1173 "Document Attachment Details"
{
    Caption = 'Attached Documents';
    DelayedInsert = true;
    Editable = true;
    PageType = List;
    SourceTable = "Document Attachment";
    SourceTableView = sorting(ID, "Table ID");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec."File Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the filename of the attachment.';

                    trigger OnDrillDown()
                    var
                        Selection: Integer;
                    begin
                        if Rec.HasContent() then
                            Rec.Export(true)
                        else
                            if not IsOfficeAddin or not EmailHasAttachments then
                                InitiateUploadFile()
                            else begin
                                Selection := StrMenu(MenuOptionsTxt, 1, SelectInstructionTxt);
                                case
                                    Selection of
                                    1:
                                        InitiateAttachFromEmail();
                                    2:
                                        InitiateUploadFile();
                                end;
                            end;
                    end;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the file extension of the attachment.';
                }
                field("File Type"; Rec."File Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the attachment is.';
                }
                field(User; Rec.User)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the user who attached the document.';
                }
                field("Attached Date"; Rec."Attached Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the document was attached.';
                }
                field("Document Flow Purchase"; Rec."Document Flow Purchase")
                {
                    ApplicationArea = All;
                    CaptionClass = GetCaptionClass(9);
                    Editable = FlowFieldsEditable;
                    ToolTip = 'Specifies if the attachment must flow to transactions.';
                    Visible = PurchaseDocumentFlow;
                }
                field("Document Flow Sales"; Rec."Document Flow Sales")
                {
                    ApplicationArea = All;
                    CaptionClass = GetCaptionClass(11);
                    Editable = FlowFieldsEditable;
                    ToolTip = 'Specifies if the attachment must flow to transactions.';
                    Visible = SalesDocumentFlow;
                }
                field("Document Flow Service"; Rec."Document Flow Service")
                {
                    ApplicationArea = Service;
                    CaptionClass = GetCaptionClass(13);
                    Editable = FlowFieldsEditable;
                    ToolTip = 'Specifies if the attachment must flow to transactions.';
                    Visible = ServiceDocumentFlow;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsVisible;
                Enabled = not IsMultiSelect;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Open);
                end;
            }
            action(EditInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can edit the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = (ShareOptionsVisible and ShareEditOptionVisible);
                Enabled = not IsMultiSelect;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Edit);
                end;
            }
            action(ShareWithOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Share';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and share the file. You can also see who it''s already shared with.', Comment = 'OneDrive should not be translated';
                Image = Share;
                Visible = ShareOptionsVisible;
                Enabled = not IsMultiSelect;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Share);
                end;
            }
            action(Preview)
            {
                ApplicationArea = All;
                Caption = 'Download';
                Image = Download;
                Enabled = DownloadEnabled;
                Scope = Repeater;
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    if Rec."File Name" <> '' then
                        Rec.Export(true);
                end;
            }
            action(AttachFromEmail)
            {
                ApplicationArea = All;
                Caption = 'Attach from email';
                Image = Email;
                Enabled = EmailHasAttachments;
                Scope = Page;
                ToolTip = 'Attach files directly from email.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    InitiateAttachFromEmail();
                end;
            }
            fileuploadaction(AttachmentsUpload)
            {
                ApplicationArea = All;
                Caption = 'Attach files';
                Image = Document;
                Enabled = true;
                Scope = Page;
                ToolTip = 'Upload one or more files';
                Visible = true;
                AllowMultipleFiles = true;

                trigger OnAction(files: List of [FileUpload])
                var
                    DocumentAttachment: Record "Document Attachment";
                begin
                    DocumentAttachment.SaveAttachment(files, FromRecRef);
                end;
            }
            action(UploadFile)
            {
                ApplicationArea = All;
                Caption = 'Attach a file';
                Image = Document;
                Enabled = true;
                Scope = Page;
                ToolTip = 'Upload one file';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    InitiateUploadFile();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Preview_Promoted; Preview)
            {
            }
            group(OneDrive_Process)
            {
                ShowAs = SplitButton;
                Caption = 'OneDrive';

                actionref(OpenInOneDrive_Promoted; OpenInOneDrive)
                {
                }
                actionref(EditInOneDrive_Promoted; EditInOneDrive)
                {
                }
                actionref(ShareWithOneDrive_Promoted; ShareWithOneDrive)
                {
                }
            }
            actionref(AttachFromEmail_Promoted; AttachFromEmail)
            {
            }
            actionref(UploadFile_Promoted; UploadFile)
            {
            }
            actionref(AttachMultipleFiles_Promoted; AttachmentsUpload)
            {
            }
        }
    }

    trigger OnInit()
    begin
        FlowFieldsEditable := true;
        IsOfficeAddin := OfficeMgmt.IsAvailable();

        if IsOfficeAddin then
            EmailHasAttachments := OfficeHostMgmt.EmailHasAttachments()
        else
            EmailHasAttachments := false;
    end;

    trigger OnAfterGetCurrRecord()
    var
        SelectedDocumentAttachment: Record "Document Attachment";
        DocumentSharing: Codeunit "Document Sharing";
    begin
        CurrPage.SetSelectionFilter(SelectedDocumentAttachment);
        IsMultiSelect := SelectedDocumentAttachment.Count() > 1;
        if OfficeMgmt.IsAvailable() or OfficeMgmt.IsPopOut() then begin
            ShareOptionsVisible := false;
            ShareEditOptionVisible := false;
        end else begin
            ShareOptionsVisible := (Rec.HasContent()) and (DocumentSharing.ShareEnabled());
            ShareEditOptionVisible := DocumentSharing.EditEnabledForFile('.' + Rec."File Extension");
        end;
        DownloadEnabled := Rec.HasContent() and (not IsMultiSelect);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."File Name" := SelectFileTxt;
    end;

    var
        OfficeMgmt: Codeunit "Office Management";
        OfficeHostMgmt: Codeunit "Office Host Management";
        SalesDocumentFlow, ServiceDocumentFlow : Boolean;
        FileDialogTxt: Label 'Attachments (%1)|%1', Comment = '%1=file types, such as *.txt or *.docx';
        FilterTxt: Label '*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.tiff;*.tif;*.pdf;*.docx;*.doc;*.xlsx;*.xls;*.pptx;*.ppt;*.msg;*.xml;*.*', Locked = true;
        ImportTxt: Label 'Attach a document.';
        SelectFileTxt: Label 'Attach a file';
        PurchaseDocumentFlow: Boolean;
        ShareOptionsVisible: Boolean;
        ShareEditOptionVisible: Boolean;
        DownloadEnabled: Boolean;
        FlowFieldsEditable: Boolean;
        EmailHasAttachments: Boolean;
        IsOfficeAddin: Boolean;
        IsMultiSelect: Boolean;
        FlowToPurchTxt: Label 'Flow to Purch. Trx';
        FlowToSalesTxt: Label 'Flow to Sales Trx';
        FlowToServiceTxt: Label 'Flow to Service Trx';
        MenuOptionsTxt: Label 'Attach from email,Upload file', Comment = 'Comma seperated phrases must be translated seperately.';
        SelectInstructionTxt: Label 'Choose the files to attach.';

    protected var
        FromRecRef: RecordRef;

    local procedure InitiateAttachFromEmail()
    begin
        OfficeMgmt.InitiateSendToAttachments(FromRecRef);
        CurrPage.Update(true);
    end;

    local procedure InitiateUploadFile()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        ImportWithFilter(TempBlob, FileName);
        if FileName <> '' then
            DocumentAttachment.SaveAttachment(FromRecRef, FileName, TempBlob);
        CurrPage.Update(true);
    end;

    local procedure GetCaptionClass(FieldNo: Integer): Text
    begin
        if SalesDocumentFlow and PurchaseDocumentFlow and ServiceDocumentFlow then
            case FieldNo of
                9:
                    exit(FlowToPurchTxt);
                11:
                    exit(FlowToSalesTxt);
                13:
                    exit(FlowToServiceTxt);
            end;
    end;

    procedure OpenForRecRef(RecRef: RecordRef)
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    begin
        Rec.Reset();

        FromRecRef := RecRef;

        SalesDocumentFlow := DocumentAttachmentMgmt.IsSalesDocumentFlow(RecRef.Number);
        PurchaseDocumentFlow := DocumentAttachmentMgmt.IsPurchaseDocumentFlow(RecRef.Number);
        ServiceDocumentFlow := DocumentAttachmentMgmt.IsServiceDocumentFlow(RecRef.Number);
        FlowFieldsEditable := DocumentAttachmentMgmt.IsFlowFieldsEditable(RecRef.Number);

        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRefInternal(Rec, RecRef, false);

        OnAfterOpenForRecRef(Rec, RecRef, FlowFieldsEditable);
    end;

    local procedure ImportWithFilter(var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
    var
        FileManagement: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImportWithFilter(TempBlob, FileName, IsHandled, FromRecRef);
        if IsHandled then
            exit;

        FileName := FileManagement.BLOBImportWithFilter(
            TempBlob, ImportTxt, FileName, StrSubstNo(FileDialogTxt, FilterTxt), FilterTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FlowFieldsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportWithFilter(var TempBlob: Codeunit "Temp Blob"; var FileName: Text; var IsHandled: Boolean; RecRef: RecordRef)
    begin
    end;
}

