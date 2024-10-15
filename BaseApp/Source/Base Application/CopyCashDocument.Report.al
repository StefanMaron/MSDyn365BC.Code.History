report 11744 "Copy Cash Document"
{
    Caption = 'Copy Cash Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CashDeskNo; CashDeskNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Cash Desk No.';
                        ToolTip = 'Specifies the number of the cash desk from which is created cash document that is processed by the report or batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupCashDeskNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateCashDeskNo;
                        end;
                    }
                    field(DocumentType; DocType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Cash Document,Posted Cash Document';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo;
                        end;
                    }
                    field(IncludeHeader_Options; IncludeHeader)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the information from the document header.';
                    }
                    field(RecalculateLines; RecalculateLines)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the cash document you are creating.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (CashDeskNo <> '') and (DocNo <> '') then begin
                case DocType of
                    DocType::"Cash Document":
                        if FromCashDocHeader.Get(CashDeskNo, DocNo) then
                            ;
                    DocType::"Posted Cash Document":
                        if FromPostedCashDocHeader.Get(CashDeskNo, DocNo) then
                            FromCashDocHeader.TransferFields(FromPostedCashDocHeader);
                end;
                if FromCashDocHeader."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo;

            IncludeHeader := true;
            RecalculateLines := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CopyDocMgt.SetProperties(IncludeHeader, RecalculateLines, false, false, false, false, false);
        CopyDocMgt.CopyCashDoc(DocType, CashDeskNo, DocNo, CashDocHeader);
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        FromCashDocHeader: Record "Cash Document Header";
        FromPostedCashDocHeader: Record "Posted Cash Document Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        DocType: Option "Cash Document","Posted Cash Document";
        DocNo: Code[20];
        CashDeskNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;

    [Scope('OnPrem')]
    procedure SetCashDocument(var NewCashDocHeader: Record "Cash Document Header")
    begin
        NewCashDocHeader.TestField("No.");
        CashDocHeader := NewCashDocHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if (CashDeskNo = '') or (DocNo = '') then
            FromCashDocHeader.Init
        else
            if FromCashDocHeader."No." = '' then begin
                FromCashDocHeader.Init();
                case DocType of
                    DocType::"Cash Document":
                        FromCashDocHeader.Get(CashDeskNo, DocNo);
                    DocType::"Posted Cash Document":
                        begin
                            FromPostedCashDocHeader.Get(CashDeskNo, DocNo);
                            FromCashDocHeader.TransferFields(FromPostedCashDocHeader);
                        end;
                end;
            end;
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::"Cash Document":
                begin
                    FromCashDocHeader."No." := DocNo;
                    if CashDeskNo <> '' then
                        FromCashDocHeader.SetRange("Cash Desk No.", CashDeskNo);
                    FromCashDocHeader.SetRange("Cash Document Type", CashDocHeader."Cash Document Type");
                    FromCashDocHeader.SetRange("Currency Code", CashDocHeader."Currency Code");
                    if PAGE.RunModal(0, FromCashDocHeader) = ACTION::LookupOK then begin
                        CashDeskNo := FromCashDocHeader."Cash Desk No.";
                        DocNo := FromCashDocHeader."No.";
                    end;
                end;
            DocType::"Posted Cash Document":
                begin
                    FromPostedCashDocHeader."No." := DocNo;
                    if CashDeskNo <> '' then
                        FromPostedCashDocHeader.SetRange("Cash Desk No.", CashDeskNo);
                    FromPostedCashDocHeader.SetRange("Cash Document Type", CashDocHeader."Cash Document Type");
                    FromPostedCashDocHeader.SetRange("Currency Code", CashDocHeader."Currency Code");
                    if PAGE.RunModal(0, FromPostedCashDocHeader) = ACTION::LookupOK then begin
                        CashDeskNo := FromPostedCashDocHeader."Cash Desk No.";
                        DocNo := FromPostedCashDocHeader."No.";
                    end;
                end;
        end;
        ValidateDocNo;
    end;

    local procedure ValidateCashDeskNo()
    var
        CashDeskManagement: Codeunit CashDeskManagement;
    begin
        CashDeskManagement.CheckCashDesk(CashDeskNo);
        ValidateDocNo;
    end;

    local procedure LookupCashDeskNo()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc."No." := CashDeskNo;
        BankAcc.SetRange("Currency Code", CashDocHeader."Currency Code");
        if PAGE.RunModal(PAGE::"Cash Desk List", BankAcc) = ACTION::LookupOK then
            CashDeskNo := BankAcc."No.";

        ValidateDocNo;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewDocType: Option "Cash Document","Posted Cash Document"; NewCashDeskNo: Code[20]; NewDocNo: Code[20])
    begin
        DocType := NewDocType;
        CashDeskNo := NewCashDeskNo;
        DocNo := NewDocNo;
    end;
}

