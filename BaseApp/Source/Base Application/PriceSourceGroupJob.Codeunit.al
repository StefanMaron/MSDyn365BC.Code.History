codeunit 7015 "Price Source Group - Job" implements "Price Source Group"
{
    var
        JobSourceType: Enum "Job Price Source Type";

    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := JobSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType))
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::Job);
    end;
}