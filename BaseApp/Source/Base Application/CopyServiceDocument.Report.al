report 5979 "Copy Service Document"
{
    Caption = 'Copy Service Document';
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
                        ApplicationArea = Service;
                        Caption = 'Document Type';
                        OptionCaption = 'Quote,Contract';
                        ToolTip = 'Specifies the type of service document that you want to copy.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number that you want to copy from by choosing the field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo;
                        end;
                    }
                    field("FromServContractHeader.""Customer No."""; FromServContractHeader."Customer No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the customer.';
                    }
                    field("FromServContractHeader.Name"; FromServContractHeader.Name)
                    {
                        ApplicationArea = Service;
                        Caption = 'Customer Name';
                        Editable = false;
                        ToolTip = 'Specifies the customer name from a document that you have selected to copy the information from.';
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
                    DocType::Quote:
                        if FromServContractHeader.Get(FromServContractHeader."Contract Type"::Quote, DocNo) then
                            ;
                    DocType::Contract:
                        if FromServContractHeader.Get(FromServContractHeader."Contract Type"::Contract, DocNo) then
                            ;
                end;
                if FromServContractHeader."Contract No." = '' then
                    DocNo := ''
                else
                    FromServContractHeader.CalcFields(Name);
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit();
        if not AllLinesCopied then
            if ConfirmManagement.GetResponse(Text000, true) then begin
                OutServContractLine.MarkedOnly := true;
                PAGE.RunModal(PAGE::"Service Contract Line List", OutServContractLine);
            end;
    end;

    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if DocNo = '' then
            Error(Text004);
        ValidateDocNo;
        if FromServContractHeader."Ship-to Code" <> ServContractHeader."Ship-to Code" then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                CurrReport.Quit;
        AllLinesCopied := CopyDocMgt.CopyServContractLines(ServContractHeader, DocType, DocNo, OutServContractLine);
    end;

    var
        ServContractHeader: Record "Service Contract Header";
        FromServContractHeader: Record "Service Contract Header";
        OutServContractLine: Record "Service Contract Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        DocType: Option Quote,Contract;
        DocNo: Code[20];
        AllLinesCopied: Boolean;
        Text000: Label 'It was not possible to copy all of the service contract lines.\\Do you want to see these lines?';
        Text002: Label 'You can only copy the document with the same %1.';
        Text003: Label 'The document has a different ship-to code.\\Do you want to continue?';
        Text004: Label 'You must fill in the Document No. field.';

    procedure SetServContractHeader(var NewServContractHeader: Record "Service Contract Header")
    begin
        ServContractHeader := NewServContractHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromServContractHeader.Init
        else begin
            FromServContractHeader.Init();
            FromServContractHeader.Get(DocType, DocNo);
            if FromServContractHeader."Customer No." <> ServContractHeader."Customer No." then
                Error(Text002, ServContractHeader.FieldCaption("Customer No."));
            if FromServContractHeader."Currency Code" <> ServContractHeader."Currency Code" then
                Error(Text002, ServContractHeader.FieldCaption("Currency Code"));
            FromServContractHeader.CalcFields(Name);
        end;
    end;

    local procedure LookupDocNo()
    begin
        FromServContractHeader.FilterGroup := 2;
        FromServContractHeader.SetRange("Contract Type", CopyDocMgt.ServContractHeaderDocType(DocType));
        if ServContractHeader."Contract Type" = CopyDocMgt.ServContractHeaderDocType(DocType) then
            FromServContractHeader.SetFilter("Contract No.", '<>%1', ServContractHeader."Contract No.");
        FromServContractHeader."Contract Type" := CopyDocMgt.ServContractHeaderDocType(DocType);
        FromServContractHeader."Contract No." := DocNo;
        FromServContractHeader.SetCurrentKey("Customer No.", "Currency Code", "Ship-to Code");
        FromServContractHeader.SetRange("Customer No.", ServContractHeader."Customer No.");
        FromServContractHeader.SetRange("Currency Code", ServContractHeader."Currency Code");
        FromServContractHeader.FilterGroup := 0;
        FromServContractHeader.SetRange("Ship-to Code", ServContractHeader."Ship-to Code");
        if PAGE.RunModal(0, FromServContractHeader) = ACTION::LookupOK then
            DocNo := FromServContractHeader."Contract No.";
        ValidateDocNo;
    end;

    procedure InitializeRequest(DocumentType: Option; DocumentNo: Code[20])
    begin
        DocType := DocumentType;
        DocNo := DocumentNo;
    end;
}

