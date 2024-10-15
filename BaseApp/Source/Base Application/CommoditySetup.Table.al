table 31096 "Commodity Setup"
{
    Caption = 'Commodity Setup';
    DataCaptionFields = "Commodity Code";
#if CLEAN17
    ObsoleteState = Removed;
#else
    DrillDownPageID = "Commodity Setup";
    LookupPageID = "Commodity Setup";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Commodity Code"; Code[10])
        {
            Caption = 'Commodity Code';
            NotBlank = true;
#if not CLEAN17
            TableRelation = Commodity;
#endif
        }
        field(2; "Valid From"; Date)
        {
            Caption = 'Valid From';
            NotBlank = true;
        }
        field(3; "Valid To"; Date)
        {
            Caption = 'Valid To';
        }
        field(4; "Commodity Limit Amount LCY"; Decimal)
        {
            Caption = 'Commodity Limit Amount LCY';
        }
    }

    keys
    {
        key(Key1; "Commodity Code", "Valid From")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

