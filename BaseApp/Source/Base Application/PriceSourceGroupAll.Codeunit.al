codeunit 7012 "Price Source Group - All" implements "Price Source Group"
{
    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    begin
        exit(true)
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::All);
    end;
}