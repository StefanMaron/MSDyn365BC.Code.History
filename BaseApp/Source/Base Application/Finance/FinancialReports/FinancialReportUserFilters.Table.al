namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;
using System.Security.AccessControl;

table 89 "Financial Report User Filters"
{
    Caption = 'Financial Report User Filters';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            TableRelation = User;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; "Financial Report Name"; Code[10])
        {
            TableRelation = "Financial Report";
            DataClassification = SystemMetadata;
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
        field(51; "Row Definition"; Code[10])
        {
            Caption = 'Row Definition';
            DataClassification = SystemMetadata;
        }
        field(52; "Column Definition"; Code[10])
        {
            Caption = 'Column Definition';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User ID", "Financial Report Name")
        {
            Clustered = true;
        }
    }
}