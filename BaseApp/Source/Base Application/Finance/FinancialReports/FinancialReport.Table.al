namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;

table 88 "Financial Report"
{
    Caption = 'Financial Report';
    DataCaptionFields = Name, Description;
    LookupPageID = "Financial Reports";
    DataClassification = CustomerContent;

    fields
    {
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(3; UseAmountsInAddCurrency; Boolean)
        {
            Caption = 'Use Amounts in Additional Currency';
            DataClassification = SystemMetadata;
        }
        field(4; PeriodType; Enum "Analysis Period Type")
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
        }
        field(5; ShowLinesWithShowNo; Boolean)
        {
            Caption = 'Show All Lines';
            DataClassification = SystemMetadata;
        }
        field(6; Dim1Filter; Text[2048])
        {
            Caption = 'Dimension 1 Filter';
            DataClassification = SystemMetadata;
        }
        field(7; Dim2Filter; Text[2048])
        {
            Caption = 'Dimension 2 Filter';
            DataClassification = SystemMetadata;
        }
        field(8; Dim3Filter; Text[2048])
        {
            Caption = 'Dimension 3 Filter';
            DataClassification = SystemMetadata;
        }
        field(9; Dim4Filter; Text[2048])
        {
            Caption = 'Dimension 4 Filter';
            DataClassification = SystemMetadata;
        }
        field(10; CostCenterFilter; Text[2048])
        {
            Caption = 'Cost Center Filter';
            DataClassification = SystemMetadata;
        }
        field(11; CostObjectFilter; Text[2048])
        {
            Caption = 'Cost Object Filter';
            DataClassification = SystemMetadata;
        }
        field(12; CashFlowFilter; Text[2048])
        {
            Caption = 'Cash Flow Filter';
            DataClassification = SystemMetadata;
        }
        field(13; GLBudgetFilter; Text[2048])
        {
            Caption = 'G/L Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(14; CostBudgetFilter; Text[2048])
        {
            Caption = 'Cost Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(15; DateFilter; Text[2048])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        // Fields not in "FinancialReportUserFilters"
        field(50; Description; Text[80])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(51; "Financial Report Row Group"; Code[10])
        {
            Caption = 'Financial Report Row Group';
            TableRelation = "Acc. Schedule Name";
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
            end;
        }
        field(52; "Financial Report Column Group"; Code[10])
        {
            Caption = 'Financial Report Column Group';
            TableRelation = "Column Layout Name";
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
            end;

        }
    }
    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    var
        AccSchedManagement: Codeunit AccSchedManagement;

    trigger OnInsert()
    begin
        AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
    end;

}