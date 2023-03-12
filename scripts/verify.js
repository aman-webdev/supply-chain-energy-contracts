const { run } = require("hardhat")
module.exports = async (address, constructorArguments) => {
    try {
        await run("verify:verify", {
            address,
            constructorArguments,
        })

        console.log("Verified")
    } catch (e) {
        console.log(e)
    }
}
