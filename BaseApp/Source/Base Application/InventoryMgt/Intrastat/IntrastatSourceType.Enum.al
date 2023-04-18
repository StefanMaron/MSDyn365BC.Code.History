enum 264 "Intrastat Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    value(0; "") { Caption = ''; }
    value(1; "Item Entry") { Caption = 'Item Entry'; }
    value(2; "Job Entry") { Caption = 'Job Entry'; }
}