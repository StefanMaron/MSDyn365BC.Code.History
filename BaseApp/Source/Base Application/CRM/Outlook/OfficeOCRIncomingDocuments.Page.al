page 1626 "Office OCR Incoming Documents"
{
    Caption = 'Office Incoming Documents';
    DataCaptionExpression = PageCaptionTxt;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Exchange Object";
    SourceTableTemporary = true;
    SourceTableView = SORTING(Name)
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send';

                    trigger OnValidate()
                    begin
                        if (IncomingDocumentAttachment."Document No. Filter" <> '') and (Count > 1) and Selected then begin
                            ModifyAll(Selected, false);
                            Selected := true;
                        end;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Count = 1 then begin
            Selected := true;
            Modify();
        end else
            if IncomingDocumentAttachment."Document No. Filter" <> '' then
                ModifyAll(Selected, false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            onSave(IncomingDocument);
    end;

    local procedure onSave(IncomingDocument: Record "Incoming Document"): Boolean
    begin
        SetRange(Selected, true);
        if FindSet() then begin
            repeat
                case InitiatedAction of
                    InitiatedAction::InitiateSendToIncomingDocuments:
                        OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment);
                    InitiatedAction::InitiateSendToOCR:
                        if OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment) then
                            OfficeMgt.SendToOCR(IncomingDocument);
                    InitiatedAction::InitiateSendToWorkFlow:
                        if OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment) then
                            OfficeMgt.SendApprovalRequest(IncomingDocument);
                end;
            until Next() = 0;
            OfficeMgt.DisplaySuccessMessage(Rec);
        end;
    end;

    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OfficeMgt: Codeunit "Office Management";
        PageCaptionTxt: Label 'Select Attachment to Send';

    procedure InitializeIncomingDocumentAttachment(LinkedIncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        IncomingDocumentAttachment := LinkedIncomingDocumentAttachment;
    end;

    procedure InitializeExchangeObject(var TempExchangeObject: Record "Exchange Object" temporary)
    begin
        if TempExchangeObject.FindSet() then
            repeat
                TempExchangeObject.CalcFields(Content);
                TransferFields(TempExchangeObject);
                Insert();
            until TempExchangeObject.Next() = 0;
    end;
}

