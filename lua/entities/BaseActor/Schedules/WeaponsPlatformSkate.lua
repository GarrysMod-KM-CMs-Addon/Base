// Currently only this for now
// TODO: Support epic slow walking while shooting them
RegisterSchedule( "WeaponsPlatformSkate", { Execute = function( self, pSchedule, MyTable )
	MyTable.SetSchedule( self, "WeaponsPlatformSkateMelee", MyTable )
end } )
