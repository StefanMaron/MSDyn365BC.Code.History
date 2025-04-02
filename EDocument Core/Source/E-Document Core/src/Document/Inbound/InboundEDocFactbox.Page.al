// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Text;
using System.Utilities;

page 6108 "Inbound E-Doc. Factbox"
{
    PageType = CardPart;
    UsageCategory = None;
    ApplicationArea = Basic, Suite;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTable = "E-Document Service Status";

    layout
    {
        area(Content)
        {
            field("E-Document Service"; Rec."E-Document Service Code")
            {
                Caption = 'Service';
                ToolTip = 'Specifies the service code of an E-Document';
            }
            field("Status"; Rec.Status)
            {
                Caption = 'Service Status';
                ToolTip = 'Specifies the status of an E-Document';
            }
            field("Processing Status"; Format(Rec."Import Processing Status"))
            {
                Caption = 'Processing Status';
                ToolTip = 'Specifies the processing status of an E-Document';
                Editable = false;
                Visible = ImportProcessingStatusVisible;
            }
            field(Logs; Rec.Logs())
            {
                Caption = 'Document Logs';
                ToolTip = 'Specifies the count of logs for an E-Document';

                trigger OnDrillDown()
                begin
                    Rec.ShowLogs();
                end;
            }
            field(HttpLogs; Rec.IntegrationLogs())
            {
                Caption = 'Integration Logs';
                ToolTip = 'Specifies the count of communication logs for an E-Document';

                trigger OnDrillDown()
                begin
                    Rec.ShowIntegrationLogs();
                end;
            }
            group(PDF)
            {
                Visible = IsPdf;
                ShowCaption = false;
                usercontrol(PDFViewer; "PDF Viewer")
                {
                    ApplicationArea = All;

                    trigger ControlAddinReady()
                    begin
                        ControlAddInReady := true;
                        SetPDFDocument();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextPdfPage)
            {
                Caption = 'Next pdf page';
                ApplicationArea = All;
                Visible = IsPdf;

                trigger OnAction()
                begin
                    CurrPage.PDFViewer.NextPage();
                end;
            }
            action(PreviousPdfPage)
            {
                Caption = 'Previous pdf page';
                ApplicationArea = All;
                Visible = IsPdf;

                trigger OnAction()
                begin
                    CurrPage.PDFViewer.PreviousPage();
                end;
            }
        }
    }

    var
        EDocument: Record "E-Document";
        IsPdf, ControlAddInReady : Boolean;
        ImportProcessingStatusVisible, Visible, Loaded : Boolean;

    trigger OnOpenPage()
    var
        EDocumentsSetup: Record "E-Documents Setup";
    begin
        ImportProcessingStatusVisible := EDocumentsSetup.IsNewEDocumentExperienceActive();
    end;

    trigger OnAfterGetRecord()
    begin
        if EDocument.Get(Rec."E-Document Entry No") then;
        IsPdf := EDocument."File Type" = EDocument."File Type"::PDF;

        // If new record is selected, then reload the PDF document
        if Rec."E-Document Entry No" <> xRec."E-Document Entry No" then
            SetPDFDocument();
    end;

    local procedure SetPDFDocument()
    var
        EDocumentDataStorage: Record "E-Doc. Data Storage";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStreamVar: InStream;
        PDFAsTxt: Text;
    begin
        if not ControlAddInReady then
            exit;

        if (EDocument."Unstructured Data Entry No." <> 0) and (not Loaded) then begin
            Visible := true;
            EDocumentDataStorage.Get(EDocument."Unstructured Data Entry No.");
            EDocumentDataStorage.CalcFields("Data Storage");
            TempBlob.FromRecord(EDocumentDataStorage, EDocumentDataStorage.FieldNo("Data Storage"));

            TempBlob.CreateInStream(InStreamVar);
            PDFAsTxt := Base64Convert.ToBase64(InStreamVar);
            CurrPage.PDFViewer.LoadPDF(PDFAsTxt);
            Loaded := true;
        end;
        CurrPage.PDFViewer.SetVisible(Visible);
    end;

}


