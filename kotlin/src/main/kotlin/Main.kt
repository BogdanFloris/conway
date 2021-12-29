fun main() {
    val conway = newConwayGameFromFile("../seeds/test.txt")
    println(conway.toString())
    while (true) {
        conway.step()
        println(conway.toString())
        Thread.sleep(1_000)
    }
}