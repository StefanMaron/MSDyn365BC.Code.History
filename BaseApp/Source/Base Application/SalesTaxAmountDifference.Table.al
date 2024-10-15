table 10012 "Sales Tax Amount Difference"
{
    Caption = 'Sales Tax Amount Difference';

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Document Product Area"; Option)
        {
            Caption = 'Document Product Area';
            OptionCaption = 'Sales,Purchase,Service,,,,Posted Sale,Posted Purchase,Posted Service';
            OptionMembers = Sales,Purchase,Service,,,,"Posted Sale","Posted Purchase","Posted Service";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Document Product Area" = CONST(Sales)) "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF ("Document Product Area" = CONST(Purchase)) "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF ("Document Product Area" = CONST(Service)) "Service Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF ("Document Type" = CONST(Invoice),
                                     "Document Product Area" = CONST("Posted Sale")) "Sales Invoice Header"
            ELSE
            IF ("Document Type" = CONST("Credit Memo"),
                                              "Document Product Area" = CONST("Posted Sale")) "Sales Cr.Memo Header"
            ELSE
            IF ("Document Type" = CONST(Invoice),
                                                       "Document Product Area" = CONST("Posted Purchase")) "Purch. Inv. Header"
            ELSE
            IF ("Document Type" = CONST("Credit Memo"),
                                                                "Document Product Area" = CONST("Posted Purchase")) "Purch. Cr. Memo Hdr."
            ELSE
            IF ("Document Type" = CONST(Invoice),
                                                                         "Document Product Area" = CONST("Posted Service")) "Service Invoice Header"
            ELSE
            IF ("Document Type" = CONST("Credit Memo"),
                                                                                  "Document Product Area" = CONST("Posted Service")) "Service Cr.Memo Header";
        }
        field(5; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(6; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        field(7; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(8; "Tax %"; Decimal)
        {
            Caption = 'Tax %';
        }
        field(9; "Expense/Capitalize"; Boolean)
        {
            Caption = 'Expense/Capitalize';
        }
        field(10; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            OptionCaption = 'Sales and Use Tax,Excise Tax,Sales Tax Only,Use Tax Only';
            OptionMembers = "Sales and Use Tax","Excise Tax","Sales Tax Only","Use Tax Only";
        }
        field(11; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(15; "Tax Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Difference';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Product Area", "Document Type", "Document No.", "Tax Area Code", "Tax Jurisdiction Code", "Tax %", "Tax Group Code", "Expense/Capitalize", "Tax Type", "Use Tax")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ClearDocDifference(ProductArea: Option Sales,Purchase; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20])
    var
        TaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        TaxAmountDifference.Reset;
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocType);
        TaxAmountDifference.SetRange("Document No.", DocNo);
        if TaxAmountDifference.FindFirst then
            TaxAmountDifference.DeleteAll;
    end;

    procedure AnyTaxDifferenceRecords(ProductArea: Option Sales,Purchase; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]): Boolean
    var
        TaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        TaxAmountDifference.Reset;
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocType);
        TaxAmountDifference.SetRange("Document No.", DocNo);
        exit(TaxAmountDifference.FindFirst);
    end;

    procedure CopyTaxDifferenceRecords(FromProductArea: Option Sales,Purchase; FromDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; FromDocNo: Code[20]; ToProductArea: Option ,,,,,,"Posted Sale","Posted Purchase"; ToDocType: Option ,,Invoice,"Credit Memo"; ToDocNo: Code[20])
    var
        FromTaxAmountDifference: Record "Sales Tax Amount Difference";
        ToTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        FromTaxAmountDifference.Reset;
        FromTaxAmountDifference.SetRange("Document Product Area", FromProductArea);
        FromTaxAmountDifference.SetRange("Document Type", FromDocType);
        FromTaxAmountDifference.SetRange("Document No.", FromDocNo);
        if FromTaxAmountDifference.Find('-') then begin
            ToTaxAmountDifference.Init;
            ToTaxAmountDifference."Document Product Area" := ToProductArea;
            ToTaxAmountDifference."Document Type" := ToDocType;
            ToTaxAmountDifference."Document No." := ToDocNo;
            repeat
                ToTaxAmountDifference."Tax Area Code" := FromTaxAmountDifference."Tax Area Code";
                ToTaxAmountDifference."Tax Jurisdiction Code" := FromTaxAmountDifference."Tax Jurisdiction Code";
                ToTaxAmountDifference."Tax %" := FromTaxAmountDifference."Tax %";
                ToTaxAmountDifference."Tax Group Code" := FromTaxAmountDifference."Tax Group Code";
                ToTaxAmountDifference."Expense/Capitalize" := FromTaxAmountDifference."Expense/Capitalize";
                ToTaxAmountDifference."Tax Type" := FromTaxAmountDifference."Tax Type";
                ToTaxAmountDifference."Use Tax" := FromTaxAmountDifference."Use Tax";
                ToTaxAmountDifference."Tax Difference" := FromTaxAmountDifference."Tax Difference";
                ToTaxAmountDifference.Insert;
            until FromTaxAmountDifference.Next = 0;
        end;
    end;
}

