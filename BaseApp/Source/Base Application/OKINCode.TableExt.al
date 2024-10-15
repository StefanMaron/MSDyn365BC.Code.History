tableextension 17361 OKINCode extends Language
{
    fields
    {
        field(17400; "OKIN Code"; Code[10])
        {
            Caption = 'OKIN Code';
            ObsoleteReason = 'Not used';
            ObsoleteState = Pending;
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('04'));
            ObsoleteTag = '15.0';
        }
    }
}