page 12188 "Manual vendor Payment Line"
{
    Caption = 'Create Manual Bill Vendor Line';
    PageType = Card;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendorNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Code';
                    NotBlank = true;
                    TableRelation = Vendor;
                    ToolTip = 'Specifies the vendor code.';

                    trigger OnValidate()
                    var
                        Vend: Record Vendor;
                    begin
                        if Vend.Get(VendorNo) then begin
                            VendorName := Vend.Name;
                            WithholdingTaxCode := Vend."Withholding Tax Code";
                            SocialSecurityCode := Vend."Social Security Code";
                        end
                    end;
                }
                field(VendorName; VendorName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies the vendor name.';
                }
                field(WithholdingTaxCode; WithholdingTaxCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Withholding Tax Code';
                    TableRelation = "Withhold Code";
                    ToolTip = 'Specifies the withholding tax code.';
                }
                field(SocialSecurityCode; SocialSecurityCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Social Security Code';
                    TableRelation = "Contribution Code";
                    ToolTip = 'Specifies the social security code.';
                }
                field(Desc; Desc)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the payment.';
                }
                field(ExternalDocNo; ExternalDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Doc. No.';
                    ToolTip = 'Specifies the external document number.';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount.';

                    trigger OnValidate()
                    begin
                        TaxBaseAmount := TotalAmount;
                    end;
                }
                field(TaxBaseAmount; TaxBaseAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Base Amount';
                    ToolTip = 'Specifies the tax base amount.';
                }
                field(DocumentType; DocumentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
                    ToolTip = 'Specifies the document type.';
                }
                field(DocumentNo; DocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number.';
                }
                field(DocumentDate; DocumentDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Date';
                    ToolTip = 'Specifies the document date.';
                }
                field(VendorBankAccount; VendorBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Bank Account';
                    ToolTip = 'Specifies the vendor bank account.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendBankAcc: Record "Vendor Bank Account";
                    begin
                        VendBankAcc.Reset;
                        VendBankAcc.SetRange("Vendor No.", VendorNo);
                        if PAGE.RunModal(PAGE::"Vendor Bank Account List", VendBankAcc, VendBankAcc.Code) = ACTION::LookupOK then
                            VendorBankAccount := VendBankAcc.Code;
                    end;

                    trigger OnValidate()
                    var
                        VendBankAcc: Record "Vendor Bank Account";
                    begin
                        if VendorBankAccount <> '' then
                            VendBankAcc.Get(VendorNo, VendorBankAccount);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(InsertLine)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Line';
                Image = Line;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Add a line.';

                trigger OnAction()
                var
                    VendorBillLine: Record "Vendor Bill Line";
                    DimMgt: Codeunit DimensionManagement;
                    Dimension: Code[20];
                    No: array[10] of Code[20];
                    TableID: array[10] of Integer;
                    NextLineNo: Integer;
                begin
                    with VendorBillLine do begin
                        LockTable;
                        Reset;
                        SetRange("Vendor Bill List No.", VendorBillNo);
                        if not FindLast then
                            NextLineNo := 10000
                        else
                            NextLineNo := "Line No." + 10000;
                        Init;
                        "Vendor Bill List No." := VendorBillNo;
                        "Line No." := NextLineNo;
                        if VendorNo <> '' then
                            "Vendor No." := VendorNo
                        else
                            Error(Text12100);
                        "Vendor Bank Acc. No." := VendorBankAccount;
                        "Document Type" := DocumentType;
                        "Document No." := DocumentNo;
                        Description := Desc;
                        "Document Date" := DocumentDate;
                        "Due Date" := PostingDate;
                        "External Document No." := ExternalDocNo;
                        "Instalment Amount" := TotalAmount;
                        "Remaining Amount" := TotalAmount;
                        "Gross Amount to Pay" := TotalAmount;
                        "Amount to Pay" := TaxBaseAmount;
                        "Manual Line" := true;
                        "Cumulative Transfers" := true;
                        SetWithholdCode(WithholdingTaxCode);
                        SetSocialSecurityCode(SocialSecurityCode);
                        TableID[1] := DATABASE::Vendor;
                        No[1] := VendorNo;
                        Dimension := '';
                        "Dimension Set ID" :=
                          DimMgt.GetDefaultDimID(
                            TableID, No, '', Dimension, Dimension, 0, 0);
                        Insert(true)
                    end;
                    ClearAll;
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        DocumentType := DocumentType::Invoice;
    end;

    var
        VendorNo: Code[20];
        VendorBillNo: Code[20];
        DocumentNo: Code[20];
        WithholdingTaxCode: Code[20];
        VendorBankAccount: Code[20];
        ExternalDocNo: Code[20];
        SocialSecurityCode: Code[20];
        VendorName: Text[100];
        Desc: Text[30];
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        DocumentDate: Date;
        PostingDate: Date;
        TotalAmount: Decimal;
        Text12100: Label 'Please enter the vendor code.';
        TaxBaseAmount: Decimal;

    [Scope('OnPrem')]
    procedure SetVendBillNoAndDueDate(VendBillNo: Code[20]; Date: Date)
    begin
        VendorBillNo := VendBillNo;
        PostingDate := Date;
    end;
}

