#if not CLEAN17
page 31069 "VIES Declaration Lines"
{
    Caption = 'VIES Declaration Lines (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "VIES Declaration Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220006)
            {
                ShowCaption = false;
                field("Trade Type"; "Trade Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies trade type for the declaration header (sales, purchases or both).';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies using European Union (EU) third-party trade service for the VIES declaration line.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';

                    trigger OnDrillDown()
                    begin
                        DrillDownAmountLCY;
                    end;
                }
                field("Trade Role Type"; "Trade Role Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the trade role for the declaration line of direct trade, intermediate trade, or property movement.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SetRange("VIES Declaration No.", VIESDeclarationHdr."Corrected Declaration No.");
        SetRange("Line Type", "Line Type"::New);
    end;

    var
        VIESDeclarationHdr: Record "VIES Declaration Header";
        VIESDeclarationLn: Record "VIES Declaration Line";
        VIESDeclarationLn2: Record "VIES Declaration Line";
        LastLineNo: Integer;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetToDeclaration(VIESDeclarationHdrNew: Record "VIES Declaration Header")
    begin
        VIESDeclarationHdr := VIESDeclarationHdrNew;
        VIESDeclarationLn.SetRange("VIES Declaration No.", VIESDeclarationHdr."No.");
        if VIESDeclarationLn.FindLast then
            LastLineNo := VIESDeclarationLn."Line No."
        else
            LastLineNo := 0;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CopyLineToDeclaration()
    begin
        CurrPage.SetSelectionFilter(VIESDeclarationLn);
        if VIESDeclarationLn.FindSet then
            repeat
                with VIESDeclarationLn2 do begin
                    Init;
                    "VIES Declaration No." := VIESDeclarationHdr."No.";
                    "Line No." := LastLineNo + 10000;
                    LastLineNo += 10000;
                    "Trade Type" := VIESDeclarationLn."Trade Type";
                    "Line Type" := VIESDeclarationLn."Line Type"::Cancellation;
                    "Related Line No." := VIESDeclarationLn."Line No.";
                    "Country/Region Code" := VIESDeclarationLn."Country/Region Code";
                    "VAT Registration No." := VIESDeclarationLn."VAT Registration No.";
                    "Amount (LCY)" := VIESDeclarationLn."Amount (LCY)";
                    "EU 3-Party Trade" := VIESDeclarationLn."EU 3-Party Trade";
                    "EU Service" := VIESDeclarationLn."EU Service";
                    "EU 3-Party Intermediate Role" := VIESDeclarationLn."EU 3-Party Intermediate Role";
                    "Trade Role Type" := VIESDeclarationLn."Trade Role Type";
                    "Number of Supplies" := VIESDeclarationLn."Number of Supplies";
                    "System-Created" := true;
                    Insert;
                    "Line No." := LastLineNo + 10000;
                    LastLineNo += 10000;
                    "Line Type" := VIESDeclarationLn."Line Type"::Correction;
                    "System-Created" := false;
                    Insert;
                end;
            until VIESDeclarationLn.Next() = 0;
    end;
}


#endif