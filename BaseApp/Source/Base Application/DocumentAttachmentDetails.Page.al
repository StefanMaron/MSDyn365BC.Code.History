page 1173 "Document Attachment Details"
{
    Caption = 'Attached Documents';
    DelayedInsert = true;
    Editable = true;
    PageType = Worksheet;
    SourceTable = "Document Attachment";
    SourceTableView = SORTING(ID, "Table ID");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; "File Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the filename of the attachment.';

                    trigger OnDrillDown()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                        FileName: Text;
                    begin
                        if "Document Reference ID".HasValue then
                            Export(true)
                        else begin
                            FileName := FileManagement.BLOBImportWithFilter(
                                TempBlob, ImportTxt, FileName, StrSubstNo(FileDialogTxt, FilterTxt), FilterTxt);
                            if FileName <> '' then
                                SaveAttachment(FromRecRef, FileName, TempBlob);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("File Extension"; "File Extension")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the file extension of the attachment.';
                }
                field("File Type"; "File Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the attachment is.';
                }
                field(User; User)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the user who attached the document.';
                }
                field("Attached Date"; "Attached Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the document was attached.';
                }
                field("Document Flow Purchase"; "Document Flow Purchase")
                {
                    ApplicationArea = All;
                    CaptionClass = GetCaptionClass(9);
                    Editable = FlowFieldsEditable;
                    ToolTip = 'Specifies if the attachment must flow to transactions.';
                    Visible = PurchaseDocumentFlow;
                }
                field("Document Flow Sales"; "Document Flow Sales")
                {
                    ApplicationArea = All;
                    CaptionClass = GetCaptionClass(11);
                    Editable = FlowFieldsEditable;
                    ToolTip = 'Specifies if the attachment must flow to transactions.';
                    Visible = SalesDocumentFlow;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Preview)
            {
                ApplicationArea = All;
                Caption = 'Preview';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Get a preview of the attachment.';

                trigger OnAction()
                begin
                    if "File Name" <> '' then
                        Export(true);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        FlowFieldsEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "File Name" := SelectFileTxt;
    end;

    var
        FromRecRef: RecordRef;
        SalesDocumentFlow: Boolean;
        FileDialogTxt: Label 'Attachments (%1)|%1', Comment = '%1=file types, such as *.txt or *.docx';
        FilterTxt: Label '*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.tiff;*.tif;*.pdf;*.docx;*.doc;*.xlsx;*.xls;*.pptx;*.ppt;*.msg;*.xml;*.*', Locked = true;
        ImportTxt: Label 'Attach a document.';
        SelectFileTxt: Label 'Select File...';
        PurchaseDocumentFlow: Boolean;
        FlowToPurchTxt: Label 'Flow to Purch. Trx';
        FlowToSalesTxt: Label 'Flow to Sales Trx';
        FlowFieldsEditable: Boolean;

    local procedure GetCaptionClass(FieldNo: Integer): Text
    begin
        if SalesDocumentFlow and PurchaseDocumentFlow then
            case FieldNo of
                9:
                    exit(FlowToPurchTxt);
                11:
                    exit(FlowToSalesTxt);
            end;
    end;

    procedure OpenForRecRef(RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
    begin
        Reset;

        FromRecRef := RecRef;

        SetRange("Table ID", RecRef.Number);

        if RecRef.Number = DATABASE::Item then begin
            SalesDocumentFlow := true;
            PurchaseDocumentFlow := true;
        end;

        case RecRef.Number of
            DATABASE::Customer,
          DATABASE::"Sales Header",
          DATABASE::"Sales Line",
          DATABASE::"Sales Invoice Header",
          DATABASE::"Sales Invoice Line",
          DATABASE::"Sales Cr.Memo Header",
          DATABASE::"Sales Cr.Memo Line":
                SalesDocumentFlow := true;
            DATABASE::Vendor,
          DATABASE::"Purchase Header",
          DATABASE::"Purchase Line",
          DATABASE::"Purch. Inv. Header",
          DATABASE::"Purch. Inv. Line",
          DATABASE::"Purch. Cr. Memo Hdr.",
          DATABASE::"Purch. Cr. Memo Line":
                PurchaseDocumentFlow := true;
        end;

        case RecRef.Number of
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item,
            DATABASE::Employee,
            DATABASE::"Fixed Asset",
            DATABASE::Job,
            DATABASE::Resource:
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    SetRange("No.", RecNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(1);
                    DocType := FieldRef.Value;
                    SetRange("Document Type", DocType);

                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    SetRange("No.", RecNo);

                    FlowFieldsEditable := false;
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value;
                    SetRange("Line No.", LineNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    SetRange("No.", RecNo);

                    FlowFieldsEditable := false;
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    SetRange("No.", RecNo);

                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value;
                    SetRange("Line No.", LineNo);

                    FlowFieldsEditable := false;
                end;
        end;

        OnAfterOpenForRecRef(Rec, RecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;
}

