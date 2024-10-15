namespace Microsoft.Service.Document;

using Microsoft.Service.Contract;

table 5936 "Service Document Register"
{
    Caption = 'Service Document Register';
    DrillDownPageID = "Service Document Registers";
    LookupPageID = "Service Document Registers";

    fields
    {
        field(1; "Source Document Type"; Enum "Service Source Document Type")
        {
            Caption = 'Source Document Type';
        }
        field(2; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
        }
        field(3; "Destination Document Type"; Enum "Service Destination Document Type")
        {
            Caption = 'Destination Document Type';
        }
        field(4; "Destination Document No."; Code[20])
        {
            Caption = 'Destination Document No.';
        }
    }

    keys
    {
        key(Key1; "Source Document Type", "Source Document No.", "Destination Document Type", "Destination Document No.")
        {
            Clustered = true;
        }
        key(Key2; "Destination Document Type", "Destination Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InsertServiceSalesDocument(ServDocType: Enum "Service Source Document Type"; ServDocNo: Code[20]; SalesDocType: Enum "Service Destination Document Type"; SalesDocNo: Code[20])
    var
        ServDocReg: Record "Service Document Register";
    begin
        if not Get(ServDocType, ServDocNo, SalesDocType, SalesDocNo) then begin
            ServDocReg.Init();
            ServDocReg."Source Document Type" := ServDocType;
            ServDocReg."Source Document No." := ServDocNo;
            ServDocReg."Destination Document Type" := SalesDocType;
            ServDocReg."Destination Document No." := SalesDocNo;
            if ServDocReg.Insert() then;
        end;
    end;

    procedure PostServiceSalesDocument(SalesDocType: Enum "Service Destination Document Type"; SalesDocNo: Code[20]; InvoiceNo: Code[20])
    var
        ServDocReg: Record "Service Document Register";
        PostedServDocReg: Record "Service Document Register";
    begin
        ServDocReg.Reset();
        ServDocReg.SetCurrentKey("Destination Document Type", "Destination Document No.");
        ServDocReg.SetRange("Destination Document Type", SalesDocType);
        ServDocReg.SetRange("Destination Document No.", SalesDocNo);
        if ServDocReg.Find('-') then
            repeat
                PostedServDocReg := ServDocReg;
                case PostedServDocReg."Destination Document Type" of
                    PostedServDocReg."Destination Document Type"::Invoice:
                        PostedServDocReg."Destination Document Type" := PostedServDocReg."Destination Document Type"::"Posted Invoice";
                    PostedServDocReg."Destination Document Type"::"Credit Memo":
                        PostedServDocReg."Destination Document Type" := PostedServDocReg."Destination Document Type"::"Posted Credit Memo";
                end;
                PostedServDocReg."Destination Document No." := InvoiceNo;
                PostedServDocReg.Insert();
                ServDocReg.Delete();
            until ServDocReg.Next() = 0;
    end;

    procedure ServiceDocument(SalesDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order"; SalesDocNo: Code[20]; var ServTable: Integer; var ServDocNo: Code[20]): Boolean
    var
        ServDocReg: Record "Service Document Register";
    begin
        ServTable := 0;
        case SalesDocType of
            SalesDocType::Invoice:
                begin
                    Clear(ServDocReg);
                    ServDocReg.SetCurrentKey("Destination Document Type", "Destination Document No.");
                    ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::Invoice);
                    ServDocReg.SetRange("Destination Document No.", SalesDocNo);
                    if ServDocReg.FindFirst() then
                        case ServDocReg."Source Document Type" of
                            ServDocReg."Source Document Type"::Order:
                                begin
                                    ServTable := Database::"Service Header";
                                    ServDocNo := ServDocReg."Source Document No.";
                                end;
                            ServDocReg."Source Document Type"::Contract:
                                begin
                                    ServTable := Database::"Service Contract Header";
                                    ServDocNo := ServDocReg."Source Document No.";
                                end;
                        end;
                end;
            SalesDocType::"Credit Memo":
                begin
                    Clear(ServDocReg);
                    ServDocReg.SetCurrentKey("Destination Document Type", "Destination Document No.");
                    ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::"Credit Memo");
                    ServDocReg.SetRange("Destination Document No.", SalesDocNo);
                    if ServDocReg.FindFirst() then
                        case ServDocReg."Source Document Type" of
                            ServDocReg."Source Document Type"::Order:
                                begin
                                    ServTable := Database::"Service Header";
                                    ServDocNo := ServDocReg."Source Document No.";
                                end;
                            ServDocReg."Source Document Type"::Contract:
                                begin
                                    ServTable := Database::"Service Contract Header";
                                    ServDocNo := ServDocReg."Source Document No.";
                                end;
                        end;
                end;
        end;

        exit(ServTable <> 0)
    end;
}

