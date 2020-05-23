
class ErrorRemover
{
    [int] RemoveError()
    {
        if( $global:MaximumErrorCount )
            { $max =
                $global:MaximumErrorCount }
        else { $max = 256 } #the default

        while ( $global:Error.Count -ge $max ){
            $global:Error.RemoveAt( 
                $global:Error.Count - 1 
            )
        }
        return $global:Error.Count
    }
}
