table 10535 "MTD-Return Details"
{
    Caption = 'Submitted VAT Return';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(2; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(3; "Period Key"; Code[10])
        {
            Caption = 'Period Key';
        }
        field(4; "VAT Due Sales"; Decimal)
        {
            Caption = 'VAT Due Sales';
        }
        field(5; "VAT Due Acquisitions"; Decimal)
        {
            Caption = 'VAT Due Acquisitions';
        }
        field(6; "Total VAT Due"; Decimal)
        {
            Caption = 'Total VAT Due';
        }
        field(7; "VAT Reclaimed Curr Period"; Decimal)
        {
            Caption = 'VAT Reclaimed Curr Period';
        }
        field(8; "Net VAT Due"; Decimal)
        {
            Caption = 'Net VAT Due';
        }
        field(9; "Total Value Sales Excl. VAT"; Decimal)
        {
            Caption = 'Total Value Sales Excl. VAT';
        }
        field(10; "Total Value Purchases Excl.VAT"; Decimal)
        {
            Caption = 'Total Value Purchases Excl.VAT';
        }
        field(11; "Total Value Goods Suppl. ExVAT"; Decimal)
        {
            Caption = 'Total Value Goods Suppl. ExVAT';
        }
        field(12; "Total Acquisitions Excl. VAT"; Decimal)
        {
            Caption = 'Total Acquisitions Excl. VAT';
        }
        field(13; Finalised; Boolean)
        {
            Caption = 'Finalised';
        }
    }

    keys
    {
        key(Key1; "Start Date", "End Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure DiffersFromReturn(MTDReturnDetails: Record "MTD-Return Details"): Boolean
    begin
        exit(
          ("VAT Due Sales" <> MTDReturnDetails."VAT Due Sales") or
          ("VAT Due Acquisitions" <> MTDReturnDetails."VAT Due Acquisitions") or
          ("Total VAT Due" <> MTDReturnDetails."Total VAT Due") or
          ("VAT Reclaimed Curr Period" <> MTDReturnDetails."VAT Reclaimed Curr Period") or
          ("Net VAT Due" <> MTDReturnDetails."Net VAT Due") or
          ("Total Value Sales Excl. VAT" <> MTDReturnDetails."Total Value Sales Excl. VAT") or
          ("Total Value Purchases Excl.VAT" <> MTDReturnDetails."Total Value Purchases Excl.VAT") or
          ("Total Value Goods Suppl. ExVAT" <> MTDReturnDetails."Total Value Goods Suppl. ExVAT") or
          ("Total Acquisitions Excl. VAT" <> MTDReturnDetails."Total Acquisitions Excl. VAT") or
          (Finalised <> MTDReturnDetails.Finalised));
    end;
}

