report 12470 "Copy Item Document"
{
    Caption = 'Copy Item Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocType; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Receipt,Shipment,Posted Receipt,Posted Shipment';
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo;
                        end;
                    }
                    field(IncludeHeader; IncludeHeader)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you want to copy information from the document header you are copying.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader;
                        end;
                    }
                    field(RecalculateLines; RecalculateLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the customer information on the new document header.';

                        trigger OnValidate()
                        begin
                            RecalculateLines := true;
                        end;
                    }
                    field(AutoFillAppliesFields; AutoFillAppliesFields)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Specify appl. entries';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then begin
                case DocType of
                    DocType::Receipt:
                        if FromItemDocHeader.Get(FromItemDocHeader."Document Type"::Receipt, DocNo) then
                            ;
                    DocType::Shipment:
                        if FromItemDocHeader.Get(FromItemDocHeader."Document Type"::Shipment, DocNo) then
                            ;
                    DocType::"Posted Receipt":
                        if FromItemRcptHeader.Get(DocNo) then
                            FromItemDocHeader.TransferFields(FromItemRcptHeader);
                    DocType::"Posted Shipment":
                        if FromItemShptHeader.Get(DocNo) then
                            FromItemDocHeader.TransferFields(FromItemShptHeader);
                end;
                if FromItemDocHeader."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CopyItemDocMgt.SetProperties(IncludeHeader, RecalculateLines, false, false, AutoFillAppliesFields);
        CopyItemDocMgt.CopyItemDoc(DocType, DocNo, ItemDocHeader)
    end;

    var
        ItemDocHeader: Record "Item Document Header";
        FromItemDocHeader: Record "Item Document Header";
        FromItemRcptHeader: Record "Item Receipt Header";
        FromItemShptHeader: Record "Item Shipment Header";
        CopyItemDocMgt: Codeunit "Copy Item Document Mgt.";
        DocType: Option Receipt,Shipment,"Posted Receipt","Posted Shipment";
        DocNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        AutoFillAppliesFields: Boolean;

    [Scope('OnPrem')]
    procedure SetItemDocHeader(var NewItemDocHeader: Record "Item Document Header")
    begin
        ItemDocHeader := NewItemDocHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromItemDocHeader.Init
        else
            if FromItemDocHeader."No." = '' then begin
                FromItemDocHeader.Init;
                case DocType of
                    DocType::Receipt,
                  DocType::Shipment:
                        FromItemDocHeader.Get(DocType, DocNo);
                    DocType::"Posted Receipt":
                        begin
                            FromItemRcptHeader.Get(DocNo);
                            FromItemDocHeader.TransferFields(FromItemRcptHeader);
                        end;
                    DocType::"Posted Shipment":
                        begin
                            FromItemShptHeader.Get(DocNo);
                            FromItemDocHeader.TransferFields(FromItemShptHeader);
                        end;
                end;
            end;
        FromItemDocHeader."No." := '';

        IncludeHeader := true;
        ValidateIncludeHeader;
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::Receipt,
            DocType::Shipment:
                begin
                    FromItemDocHeader.FilterGroup := 2;
                    FromItemDocHeader.SetRange("Document Type", DocType);
                    if ItemDocHeader."Document Type" = DocType then
                        FromItemDocHeader.SetFilter("No.", '<>%1', ItemDocHeader."No.");
                    FromItemDocHeader.FilterGroup := 0;
                    FromItemDocHeader."Document Type" := DocType;
                    FromItemDocHeader."No." := DocNo;
                    if DocType = DocType::Receipt then begin
                        if PAGE.RunModal(PAGE::"Item Receipts", FromItemDocHeader, FromItemDocHeader."No.") = ACTION::LookupOK then
                            DocNo := FromItemDocHeader."No.";
                    end else begin
                        if PAGE.RunModal(PAGE::"Item Shipments", FromItemDocHeader, FromItemDocHeader."No.") = ACTION::LookupOK then
                            DocNo := FromItemDocHeader."No.";
                    end;
                end;
            DocType::"Posted Receipt":
                begin
                    FromItemRcptHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromItemRcptHeader) = ACTION::LookupOK then
                        DocNo := FromItemRcptHeader."No.";
                end;
            DocType::"Posted Shipment":
                begin
                    FromItemShptHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromItemShptHeader) = ACTION::LookupOK then
                        DocNo := FromItemShptHeader."No.";
                end;
        end;
        ValidateDocNo;
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines :=
          not IncludeHeader;
    end;
}

