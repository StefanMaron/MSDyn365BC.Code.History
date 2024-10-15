table 17387 "Posted Absence Header"
{
    Caption = 'Posted Absence Header';
    LookupPageID = "Posted Absence Order List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Calendar Days"; Decimal)
        {
            CalcFormula = Sum ("Posted Absence Line"."Calendar Days" WHERE("Document Type" = FIELD("Document Type"),
                                                                           "Document No." = FIELD("No.")));
            Caption = 'Calendar Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Working Days"; Decimal)
        {
            CalcFormula = Sum ("Posted Absence Line"."Working Days" WHERE("Document Type" = FIELD("Document Type"),
                                                                          "Document No." = FIELD("No.")));
            Caption = 'Working Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "Start Date"; Date)
        {
            CalcFormula = Min ("Posted Absence Line"."Start Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                        "Document No." = FIELD("No.")));
            Caption = 'Start Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "End Date"; Date)
        {
            CalcFormula = Max ("Posted Absence Line"."End Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                      "Document No." = FIELD("No.")));
            Caption = 'End Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(12; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(13; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(14; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("P.Absence Order"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(24; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(26; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(30; Note; Text[50])
        {
            Caption = 'Note';
        }
        field(31; "Travel Destination"; Text[100])
        {
            Caption = 'Travel Destination';
        }
        field(32; "Travel Purpose"; Text[100])
        {
            Caption = 'Travel Purpose';
        }
        field(33; "Travel Paid by No."; Code[20])
        {
            Caption = 'Travel Paid by No.';
            TableRelation = IF ("Travel Paid By Type" = CONST(Customer)) Customer
            ELSE
            IF ("Travel Paid By Type" = CONST(Vendor)) Vendor;
        }
        field(34; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(35; "Payment Hours"; Decimal)
        {
            Caption = 'Payment Hours';
        }
        field(36; "District Coefficient"; Decimal)
        {
            Caption = 'District Coefficient';
        }
        field(37; "Allocation Type"; Option)
        {
            Caption = 'Allocation Type';
            OptionCaption = ' 3,12';
            OptionMembers = " 3","12";
        }
        field(38; "Travel Reason Document"; Text[100])
        {
            Caption = 'Travel Reason Document';
        }
        field(39; "Travel Paid By Type"; Option)
        {
            Caption = 'Travel Paid By Type';
            OptionCaption = 'Company,Customer,Vendor';
            OptionMembers = Company,Customer,Vendor;
        }
        field(44; "Use Salary Indexation"; Boolean)
        {
            Caption = 'Use Salary Indexation';
        }
        field(52; "Sick Certificate Series"; Text[10])
        {
            Caption = 'Sick Certificate Series';
        }
        field(53; "Sick Certificate No."; Text[30])
        {
            Caption = 'Sick Certificate No.';
        }
        field(54; "Sick Certificate Date"; Date)
        {
            Caption = 'Sick Certificate Date';
        }
        field(55; "Sick Certificate Reason"; Text[50])
        {
            Caption = 'Sick Certificate Reason';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        HROrderCommentLine: Record "HR Order Comment Line";
    begin
        LockTable;
        DeletePostedAbsenceLines(Rec);

        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"P.Absence Order");
        HROrderCommentLine.SetRange("No.", "No.");
        HROrderCommentLine.DeleteAll;
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Order Date", "No.");
        NavigateForm.SetHROrder("HR Order No.", "HR Order Date");
        NavigateForm.Run;
    end;

    [Scope('OnPrem')]
    procedure DeletePostedAbsenceLines(PostedAbsenceHeader: Record "Posted Absence Header")
    var
        PostedAbsenceLine: Record "Posted Absence Line";
    begin
        PostedAbsenceLine.SetRange("Document Type", PostedAbsenceHeader."Document Type");
        PostedAbsenceLine.SetRange("Document No.", PostedAbsenceHeader."No.");
        PostedAbsenceLine.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document Type", "No."));
    end;
}

