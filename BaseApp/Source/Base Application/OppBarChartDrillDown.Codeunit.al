codeunit 5050 "Opp. Bar Chart DrillDown"
{
    TableNo = "Bar Chart Buffer";

    trigger OnRun()
    begin
        if Tag = '' then
            Error(Text000);
        OpportunityEntry.SetView(Tag);
        OpportunityEntry.SetRange(Active, true);
        if OpportunityEntry.Find('-') then
            repeat
                Opportunity.Get(OpportunityEntry."Opportunity No.");
                TempOpportunity := Opportunity;
                TempOpportunity.Insert();
            until OpportunityEntry.Next = 0;

        PAGE.Run(PAGE::"Active Opportunity List", TempOpportunity);
    end;

    var
        Text000: Label 'The corresponding opportunity entries cannot be displayed because the filter expression is too long.';
        OpportunityEntry: Record "Opportunity Entry";
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
}

