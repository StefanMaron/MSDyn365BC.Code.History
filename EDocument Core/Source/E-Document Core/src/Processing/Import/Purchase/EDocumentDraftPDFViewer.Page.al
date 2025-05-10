#pragma warning disable AS0050
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument;
using System.Text;
using System.Utilities;


page 6140 "E-Document Draft PDF Viewer"
{

    Caption = 'Document';
    InsertAllowed = false;
    LinksAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;
    PageType = ListPart;
    SourceTable = "E-Document";
    ObsoleteReason = 'Will be removed';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    layout
    {
        area(Content)
        {
            usercontrol(PDFViewer; "PDF Viewer")
            {
                ApplicationArea = All;

                trigger ControlAddinReady()
                begin
                    SetPDFDocument();
                end;
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(NextPage)
            {
                Caption = 'Next page';
                ToolTip = 'Show next page';
                ApplicationArea = All;
                Image = NextRecord;
                trigger OnAction()
                begin
                    CurrPage.PDFViewer.NextPage();
                end;
            }
            action(PreviousPage)
            {
                Caption = 'Previous page';
                ToolTip = 'Show previous page';
                ApplicationArea = All;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    CurrPage.PDFViewer.PreviousPage();
                end;
            }
        }
    }

    var
        Loaded: Boolean;
        Visible: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
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
        if (Rec."Unstructured Data Entry No." <> 0) and (not Loaded) then begin
            Visible := true;
            EDocumentDataStorage.Get(Rec."Unstructured Data Entry No.");
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
#pragma warning restore AS0050